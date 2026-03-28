#include <QApplication>
#include <QWebEngineView>
#include <QWebEngineProfile>
#include <QWebEngineSettings>
#include <QUrl>
#include <QIcon>
#include <QDir>
#include <QEvent>

class MiroWindow : public QWebEngineView {
public:
    MiroWindow() {
        // Set window properties
        setWindowTitle("Miro");
        
        // Use the SVG icon we created earlier
        setWindowIcon(QIcon("/usr/share/icons/hicolor/scalable/apps/miro-app.svg"));
        
        // Isolation: Use a dedicated profile and storage path
        QString configPath = QDir::homePath() + "/.config/miro-app";
        QDir().mkpath(configPath);
        
        QWebEngineProfile *profile = new QWebEngineProfile("miro-app", this);
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
        
        // Load Miro
        load(QUrl("https://miro.com/"));
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
    
    // Pass Chromium flags for acceleration as requested
    qputenv("QTWEBENGINE_CHROMIUM_FLAGS", 
            "--enable-gpu-rasterization --enable-oop-rasterization --enable-zero-copy "
            "--enable-gpu-compositing --enable-accelerated-2d-canvas --ignore-gpu-blacklist --use-gl=desktop"
            " --enable-features=TouchpadPinch --enable-pinch");

    QApplication app(argc, argv);
    
    // Ensure we use the elementary GTK theme if possible
    app.setDesktopFileName("figma-app");

    MiroWindow win;
    win.resize(1280, 800);
    win.show();
    
    return app.exec();
}
