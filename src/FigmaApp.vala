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
        
        // Setup Fullscreen Toggle (Standard F11 + User-requested CTRL+F11)
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
        
        // Primary is Ctrl, and we add both as possible accelerators
        this.set_accels_for_action ("app.fullscreen_toggle", new string[] { "F11", "<Primary>F11" });

        // Setup Quit (Standard CTRL + Q)
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

        // HeaderBar matching Files app
        var header = new Gtk.HeaderBar ();
        header.show_close_button = true;
        header.title = "Figma"; // Sets a standard centered title
        
        set_titlebar (header);

        // Set Icon
        try {
            set_icon_from_file ("/usr/share/icons/hicolor/scalable/apps/figma-app.svg");
        } catch (Error e) {
            warning ("Could not load icon: %s", e.message);
        }

        // Apply Native Style & Rounded Corners
        // 'rounded' and 'csd' classes are standard for Granite apps
        this.get_style_context ().add_class ("rounded");
        this.get_style_context ().add_class ("csd");

        var css_provider = new Gtk.CssProvider ();
        // Critical: Using border-radius and overflow: hidden on the container
        // to ensure children (WebView) are clipped at the bottom.
        string css = "window#com-figma-native, window#com-figma-native decoration { border-radius: 12px; } " +
                     "window#com-figma-native scrolledwindow { border-radius: 0 0 12px 12px; overflow: hidden; } " +
                     "window#com-figma-native webview { background-color: transparent; }";
        try {
            css_provider.load_from_data (css);
            this.get_style_context ().add_provider (css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
        } catch (Error e) {
            warning ("Could not load CSS: %s", e.message);
        }

        // WebKit View
        var webview = new WebKit.WebView ();
        var settings = webview.get_settings ();
        
        // Performance & Features
        settings.enable_developer_extras = true;
        settings.enable_webgl = true;
        settings.hardware_acceleration_policy = WebKit.HardwareAccelerationPolicy.ALWAYS;
        
        // Make background transparent so the window's rounded corners can show through
        var transparent = Gdk.RGBA () { alpha = 0.0 };
        webview.set_background_color (transparent);
        
        // Figma-specific User Agent
        settings.user_agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

        // Add to window
        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (webview);
        add (scrolled);

        webview.load_uri ("https://www.figma.com");

        // Handle Maximize -> Fullscreen transition
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
