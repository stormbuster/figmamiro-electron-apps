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
    private WebKit.WebView webview;
    private WebKit.WebContext context;
    private WebKit.WebsiteDataManager data_manager;

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

        // --- SESSION PERSISTENCE ---
        string data_dir = GLib.Environment.get_user_data_dir () + "/com.miro.native";
        string cache_dir = GLib.Environment.get_user_cache_dir () + "/com.miro.native";
        
        // Ensure directories exist
        GLib.DirUtils.create_with_parents (data_dir, 0700);
        GLib.DirUtils.create_with_parents (cache_dir, 0700);

        // Create DataManager via Object.new due to protected constructor in Vala
        data_manager = GLib.Object.new (typeof (WebKit.WebsiteDataManager),
            "base-data-directory", data_dir,
            "base-cache-directory", cache_dir) as WebKit.WebsiteDataManager;

        context = new WebKit.WebContext.with_website_data_manager (data_manager);
        context.set_cache_model (WebKit.CacheModel.WEB_BROWSER);
        
        // Persistent Cookies
        var cookie_manager = data_manager.get_cookie_manager ();
        cookie_manager.set_accept_policy (WebKit.CookieAcceptPolicy.ALWAYS);
        cookie_manager.set_persistent_storage (data_dir + "/cookies.db", WebKit.CookiePersistentStorage.SQLITE);
        // ---------------------------

        // WebKit View
        webview = new WebKit.WebView.with_context (context);
        var settings = webview.get_settings ();
        
        // Performance & Features
        settings.enable_developer_extras = true;
        settings.enable_webgl = true;
        settings.hardware_acceleration_policy = WebKit.HardwareAccelerationPolicy.ALWAYS;
        settings.enable_media_stream = true;
        settings.enable_mediasource = true;
        settings.enable_javascript_markup = true;
        settings.enable_smooth_scrolling = true;
        settings.enable_back_forward_navigation_gestures = true;
        
        // Miro-specific User Agent
        settings.user_agent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

        // Grant Permissions (Camera, Mic, Geolocation, etc.)
        webview.permission_request.connect ((request) => {
            if (request is WebKit.UserMediaPermissionRequest || 
                request is WebKit.GeolocationPermissionRequest || 
                request is WebKit.NotificationPermissionRequest) {
                request.allow ();
                return true;
            }
            return false;
        });

        // Main Layout
        var layout = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        layout.pack_start (header, false, false, 0);

        var scrolled = new Gtk.ScrolledWindow (null, null);
        scrolled.get_style_context ().add_class ("rounded");
        scrolled.add (webview);
        
        layout.pack_start (scrolled, true, true, 0);
        
        add (layout);

        webview.load_uri ("https://miro.com");

        // Fullscreen toggle logic refined for EOS 8
        this.window_state_event.connect ((event) => {
            bool is_fullscreen = (event.new_window_state & Gdk.WindowState.FULLSCREEN) != 0;
            
            if (is_fullscreen) {
                header.hide ();
            } else {
                header.show ();
            }

            if ((event.new_window_state & Gdk.WindowState.MAXIMIZED) != 0) {
                if (!is_fullscreen) {
                    this.fullscreen ();
                }
            }
            return false;
        });
    }
}
