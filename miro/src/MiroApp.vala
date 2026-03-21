using Gtk;
using WebKit;
using Granite;
using Hdy;

public class Miro.App : Granite.Application {
    public App () {
        Object (
            application_id: "com.miro.native",
            flags: GLib.ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        Hdy.init ();
        
        var window = new Miro.Window (this);
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
        var app = new Miro.App ();
        return app.run (args);
    }
}

public class Miro.Window : Hdy.Window {
    private Hdy.HeaderBar header;

    public Window (Gtk.Application app) {
        Object (
            application: app,
            title: "Miro",
            window_position: WindowPosition.CENTER,
            default_width: 1280,
            default_height: 800,
            name: "com-miro-native"
        );

        // HeaderBar matching EOS 8 standard
        header = new Hdy.HeaderBar ();
        header.show_close_button = true;
        header.title = "Miro";

        // Set Icon
        try {
            set_icon_from_file ("/usr/share/icons/hicolor/scalable/apps/miro-app.svg");
        } catch (Error e) {
            warning ("Could not load icon: %s", e.message);
        }

        // Apply Native Style
        this.get_style_context ().add_class ("rounded");
        this.get_style_context ().add_class ("csd");

        // WebKit View
        var webview = new WebKit.WebView ();
        var settings = webview.get_settings ();
        
        // Performance & Features
        settings.enable_developer_extras = true;
        settings.enable_webgl = true;
        settings.hardware_acceleration_policy = WebKit.HardwareAccelerationPolicy.ALWAYS;
        
        // Miro-specific User Agent
        settings.user_agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

        // Main Layout
        var layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        layout.pack_start (header, false, false, 0);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.get_style_context ().add_class ("rounded");
        scrolled.add (webview);
        
        layout.pack_start (scrolled, true, true, 0);
        
        add (layout);

        webview.load_uri ("https://miro.com");

        // Fullscreen toggle logic
        this.window_state_event.connect ((event) => {
            if ((event.new_window_state & Gdk.WindowState.FULLSCREEN) != 0) {
                header.hide ();
            } else {
                header.show ();
            }

            if ((event.new_window_state & Gdk.WindowState.MAXIMIZED) != 0) {
                if ((event.new_window_state & Gdk.WindowState.FULLSCREEN) == 0) {
                    this.fullscreen ();
                }
            }
            return false;
        });
    }
}
