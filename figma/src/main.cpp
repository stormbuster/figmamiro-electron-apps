#include <QApplication>
#include <QWebEngineView>
#include <QWebEngineProfile>
#include <QWebEngineSettings>
#include <QUrl>
#include <QIcon>
#include <QDir>
#include <QEvent>

class FigmaWindow : public QWebEngineView {
public:
    FigmaWindow() {
        // Set window properties
        setWindowTitle("Figma");
        
        // Use the SVG icon we created earlier
        setWindowIcon(QIcon("/usr/share/icons/hicolor/scalable/apps/figma-app.svg"));
        
        // Isolation: Use a dedicated profile and storage path
        QString configPath = QDir::homePath() + "/.config/figma-app";
        QDir().mkpath(configPath);
        
        QWebEngineProfile *profile = new QWebEngineProfile("figma-app", this);
        profile->setPersistentStoragePath(configPath + "/qtwebengine");
        profile->setPersistentCookiesPolicy(QWebEngineProfile::ForcePersistentCookies);
        
        // Settings for performance and Figma compatibility
        QWebEngineSettings *s = profile->settings();
        s->setAttribute(QWebEngineSettings::PlaybackRequiresUserGesture, false);
        s->setAttribute(QWebEngineSettings::JavascriptEnabled, true);
        s->setAttribute(QWebEngineSettings::PluginsEnabled, true);
        s->setAttribute(QWebEngineSettings::LocalStorageEnabled, true);
        s->setAttribute(QWebEngineSettings::LocalContentCanAccessRemoteUrls, true);
        s->setAttribute(QWebEngineSettings::XSSAuditingEnabled, false);
        s->setAttribute(QWebEngineSettings::AllowRunningInsecureContent, true);
        
        // Create page with profile
        setPage(new QWebEnginePage(profile, this));
        
        // Load Figma
        load(QUrl("https://www.figma.com/"));
    }

protected:
    // Handle the Maximize button -> Fullscreen transition as requested
    void changeEvent(QEvent *event) override {
        if (event->type() == QEvent::WindowStateChange) {
            if (isMaximized()) {
                // Trigger fullscreen when maximized (CTRL + F11 equivalent in Chromium)
                showFullScreen();
            }
        }
        QWebEngineView::changeEvent(event);
    }
};

int main(int argc, char *argv[]) {
    // High DPI support
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
    
    // Pass Chromium flags for gestures (Pinch-to-zoom)
    qputenv("QTWEBENGINE_CHROMIUM_FLAGS", "--enable-features=TouchpadPinch --enable-pinch");

    QApplication app(argc, argv);
    
    // Ensure we use the elementary GTK theme if possible
    app.setDesktopFileName("figma-app");

    FigmaWindow win;
    win.resize(1280, 800);
    win.show();
    
    return app.exec();
}
