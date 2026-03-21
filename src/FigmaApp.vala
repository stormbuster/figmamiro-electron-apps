using Gtk;
using WebKit;
using Granite;

public class Figma.App : Granite.Application {
    public App () {
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
    private bool is_fullscreen = false;

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

        // Apply Native Style & Rounded Corners
        this.get_style_context ().add_class ("rounded");
        this.get_style_context ().add_class ("csd");

        var css_provider = new Gtk.CssProvider ();
        string css = "window#com-figma-native, window#com-figma-native decoration { border-radius: 12px; } " +
                     "window#com-figma-native scrolledwindow { border-radius: 0 0 12px 12px; overflow: hidden; } " +
                     "window#com-figma-native webview { border-radius: 0 0 12px 12px; background: transparent; }";
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
        
        // Transparency for rounding
        var transparent = Gdk.RGBA () { alpha = 0.0 };
        webview.set_background_color (transparent);
        
        // Figma-specific User Agent
        settings.user_agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

        // Add to window
        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.add (webview);
        add (scrolled);

        webview.load_uri ("https://www.figma.com");

        // Sync local fullscreen state
        this.window_state_event.connect ((event) => {
            is_fullscreen = (event.new_window_state & Gdk.WindowState.FULLSCREEN) != 0;
            
            // Auto-fullscreen on maximize as requested
            if ((event.new_window_state & Gdk.WindowState.MAXIMIZED) != 0 && !is_fullscreen) {
                this.fullscreen ();
            }
            return false;
        });

        // Use AccelGroup for high-priority shortcut handling
        var accel_group = new Gtk.AccelGroup ();
        this.add_accel_group (accel_group);
        
        accel_group.connect (Gdk.Key.F11, Gdk.ModifierType.CONTROL_MASK, Gtk.AccelFlags.VISIBLE, (group, obj, key, mod) => {
            if (is_fullscreen) {
                this.unfullscreen ();
            } else {
                this.fullscreen ();
            }
            return true;
        });
    }
}
