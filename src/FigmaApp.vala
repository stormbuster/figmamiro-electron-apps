using Gtk;
using WebKit;
using Granite;

public class Figma.App : Granite.Application {
    public App () {
        Object (
            application_id: "com.figma.native",
            flags: GLib.ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var window = new Figma.Window (this);
        window.show_all ();
        
        // Setup Fullscreen Toggle
        var fullscreen_action = new SimpleAction ("fullscreen_toggle", null);
        fullscreen_action.activate.connect (() => {
            var state = window.get_window ().get_state ();
            if ((state & Gdk.WindowState.FULLSCREEN) != 0) {
                window.unfullscreen ();
            } else {
                window.fullscreen ();
            }
        });
        this.add_action (fullscreen_action);
        this.set_accels_for_action ("app.fullscreen_toggle", new string[] { "F11", "<Primary>F11" });

        // Setup Quit (CTRL + Q)
        var quit_action = new SimpleAction ("quit", null);
        quit_action.activate.connect (() => {
            this.quit ();
        });
        this.add_action (quit_action);
        this.set_accels_for_action ("app.quit", new string[] { "<Primary>Q" });
    }

    public static int main (string[] args) {
        var app = new Figma.App ();
        return app.run (args);
    }
}

public class Figma.Window : Gtk.Window {
    public Window (Gtk.Application app) {
        Object (
            application: app,
            title: "Figma",
            window_position: WindowPosition.CENTER,
            default_width: 1280,
            default_height: 800,
            name: "com-figma-native"
        );

        // Required for transparency support
        this.set_visual (this.get_screen ().get_rgba_visual ());

        // HeaderBar matching EOS 8
        var header = new Gtk.HeaderBar ();
        header.show_close_button = true;
        header.title = "Figma";
        set_titlebar (header);

        // Set Icon
        try {
            set_icon_from_file ("/usr/share/icons/hicolor/scalable/apps/figma-app.svg");
        } catch (Error e) {
            warning ("Could not load icon: %s", e.message);
        }

        // Apply Native Style
        this.get_style_context ().add_class ("terminal-window");
        this.get_style_context ().add_class ("rounded");
        this.get_style_context ().add_class ("csd");

        var css_provider = new Gtk.CssProvider ();
        // Window level CSS
        string window_css = "window#com-figma-native { background-color: transparent; border-radius: 12px; } " +
                            "window#com-figma-native decoration { border-radius: 12px; } " +
                            ".figma-container { border-radius: 0 0 12px 12px; overflow: hidden; background-color: @theme_bg_color; }";
        try {
            css_provider.load_from_data (window_css);
            this.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Could not load CSS: %s", e.message);
        }

        // WebKit Setup with CSS Injection
        var content_manager = new WebKit.UserContentManager ();
        
        // Inject CSS into the loaded page to force the content to round at the bottom
        // This is the only reliable way to clip a hardware-accelerated WebKit view in GTK3
        string injected_css = "html, body { border-radius: 0 0 12px 12px !important; overflow: hidden !important; }";
        var style_sheet = new WebKit.UserStyleSheet (
            injected_css, 
            WebKit.UserContentInjectedFrames.ALL_FRAMES, 
            WebKit.UserStyleLevel.USER, 
            null, null
        );
        content_manager.add_style_sheet (style_sheet);

        var webview = new WebKit.WebView.with_user_content_manager (content_manager);
        var settings = webview.get_settings ();
        
        // Performance & Features
        settings.enable_developer_extras = true;
        settings.enable_webgl = true;
        settings.hardware_acceleration_policy = WebKit.HardwareAccelerationPolicy.ALWAYS;
        
        // Transparent BG
        var transparent = Gdk.RGBA () { alpha = 0.0 };
        webview.set_background_color (transparent);
        
        // Figma-specific User Agent
        settings.user_agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

        // Layout
        var container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        container.get_style_context ().add_class ("figma-container");
        
        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (webview);
        
        container.pack_start (scrolled, true, true, 0);
        add (container);

        webview.load_uri ("https://www.figma.com");

        // Fullscreen toggle logic
        this.window_state_event.connect ((event) => {
            if ((event.new_window_state & Gdk.WindowState.MAXIMIZED) != 0) {
                if ((event.new_window_state & Gdk.WindowState.FULLSCREEN) == 0) {
                    this.fullscreen ();
                }
            }
            return false;
        });
    }
}
