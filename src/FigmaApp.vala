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
        
        // Setup Fullscreen Toggle (CTRL + F11 and F11)
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

        // HeaderBar matching Files/Terminal
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

        // Apply Native Style & Rounded Corners
        // 'terminal-window' ensures native bottom corner rounding in Elementary OS 8
        this.get_style_context ().add_class ("terminal-window");
        this.get_style_context ().add_class ("csd");
        this.get_style_context ().add_class ("rounded");

        var css_provider = new Gtk.CssProvider ();
        // Aggressive CSS to ensure clipping of the webview at the bottom
        string css = "window#com-figma-native, window#com-figma-native decoration { border-radius: 12px; } " +
                     ".figma-container, .figma-container scrolledwindow { border-radius: 0 0 12px 12px; overflow: hidden; } " +
                     "webview { background-color: transparent; }";
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
        
        // Transparent BG to allow parent rounding to show
        var transparent = Gdk.RGBA () { alpha = 0.0 };
        webview.set_background_color (transparent);
        
        // Figma-specific User Agent
        settings.user_agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

        // Add to window using a container that enforces clipping
        var container = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        container.get_style_context ().add_class ("figma-container");
        
        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (webview);
        
        container.pack_start (scrolled, true, true, 0);
        add (container);

        webview.load_uri ("https://www.figma.com");

        // Handle Maximize -> Fullscreen as requested
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
