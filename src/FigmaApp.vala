using Gtk;
using WebKit;
using Granite;

public class Figma.App : Granite.Application {
    public App () {
        // Set application ID - this is crucial for dock isolation
        Object (
            application_id: "com.figma.native",
            flags: ApplicationFlags.FLAGS_NONE
        );
    }

    protected override void activate () {
        var window = new Figma.Window (this);
        window.show_all ();
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
            name: "com.figma.native" // Explicitly name the window object for CSS/Dock
        );

        // HeaderBar matching Files app
        var header = new Gtk.HeaderBar ();
        header.show_close_button = true;
        
        // Window Title
        var title_label = new Gtk.Label ("Figma");
        title_label.get_style_context ().add_class ("h2");
        header.set_custom_title (title_label);
        
        set_titlebar (header);

        // Set Icon
        try {
            set_icon_from_file ("/usr/share/icons/hicolor/scalable/apps/figma-app.svg");
        } catch (Error e) {
            warning ("Could not load icon: %s", e.message);
        }

        // Apply CSS for rounded corners (8-10px radius matches Files app)
        var css_provider = new Gtk.CssProvider ();
        string css = "window.com-figma-native { border-radius: 10px; overflow: hidden; background: @theme_bg_color; } " +
                     "window.com-figma-native scrolledwindow { border-radius: 0 0 10px 10px; overflow: hidden; } " +
                     "window.com-figma-native .view { border-radius: 0 0 10px 10px; }";
        try {
            css_provider.load_from_data (css);
            this.get_style_context ().add_class ("com-figma-native");
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
        
        // Figma-specific User Agent override
        settings.user_agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

        // Add to window
        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (webview);
        add (scrolled);

        webview.load_uri ("https://www.figma.com");

        // Handle Maximize -> Fullscreen
        this.window_state_event.connect ((event) => {
            if ((event.new_window_state & Gdk.WindowState.MAXIMIZED) != 0) {
                this.fullscreen ();
            }
            return false;
        });
    }
}
