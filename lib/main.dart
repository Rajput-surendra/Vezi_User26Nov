import 'dart:io';
import 'package:country_code_picker/country_localizations.dart';
// import 'package:vezi/Helper/Color.dart';
// import 'package:vezi/Helper/Constant.dart';
// import 'package:vezi/Provider/CartProvider.dart';
// import 'package:vezi/Provider/CategoryProvider.dart';
// import 'package:vezi/Provider/FavoriteProvider.dart';
// import 'package:vezi/Provider/HomeProvider.dart';
// import 'package:vezi/Provider/ProductDetailProvider.dart';
// import 'package:vezi/Provider/UserProvider.dart';
// import 'package:vezi/Screen/starting_view/Splash.dart';
// import 'package:vezi/Screen/starting_view/welcome_one.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sizer/sizer.dart';
import 'Helper/Color.dart';
import 'Helper/Constant.dart';
import 'Helper/Demo_Localization.dart';
import 'Helper/PushNotificationService.dart';
import 'Helper/Session.dart';
import 'Helper/String.dart';
import 'Provider/CartProvider.dart';
import 'Provider/CategoryProvider.dart';
import 'Provider/FavoriteProvider.dart';
import 'Provider/HomeProvider.dart';
import 'Provider/ProductDetailProvider.dart';
import 'Provider/Theme.dart';
import 'Provider/SettingProvider.dart';
import 'Provider/UserProvider.dart';
import 'Provider/order_provider.dart';
import 'Screen/Dashboard.dart';
import 'Screen/starting_view/welcome_one.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
    systemNavigationBarColor: colors.primary, // navigation bar color
    statusBarColor: colors.primary, // status bar color
  ));
  HttpOverrides.global = MyHttpOverrides();
  await Firebase.initializeApp();
  initializedDownload();
  FirebaseMessaging.onBackgroundMessage(myForgroundMessageHandler);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
  //   statusBarColor: Colors.transparent, // status bar color
  // ));
  SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(
    ChangeNotifierProvider<ThemeNotifier>(
      create: (BuildContext context) {
        String? theme = prefs.getString(APP_THEME);

        if (theme == DARK)
          ISDARK = "true";
        else if (theme == LIGHT) ISDARK = "false";

        if (theme == null || theme == "" || theme == DEFAULT_SYSTEM) {
          prefs.setString(APP_THEME, DEFAULT_SYSTEM);
          var brightness = SchedulerBinding.instance.window.platformBrightness;
          ISDARK = (brightness == Brightness.dark).toString();

          return ThemeNotifier(ThemeMode.system);
        }

        return ThemeNotifier(theme == LIGHT ? ThemeMode.light : ThemeMode.dark);
      },
      child: MyApp(sharedPreferences: prefs),
    ),
  );
}

Future<void> initializedDownload() async {
  // await FlutterDownloader.initialize(debug: false);
}

final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class MyApp extends StatefulWidget {
  late SharedPreferences sharedPreferences;

  MyApp({Key? key, required this.sharedPreferences}) : super(key: key);

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState state = context.findAncestorStateOfType<_MyAppState>()!;
    state.setLocale(newLocale);
  }

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  setLocale(Locale locale) {
    if (mounted)
      setState(() {
        _locale = locale;
      });
  }

  @override
  void didChangeDependencies() {
    getLocale().then((locale) {
      if (mounted)
        setState(() {
          this._locale = locale;
        });
    });
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    if (this._locale == null) {
      return Container(
        child: Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color?>(colors.primary)),
        ),
      );
    } else {
      return MultiProvider(
          providers: [
            Provider<SettingProvider>(
              create: (context) => SettingProvider(widget.sharedPreferences),
            ),
            ChangeNotifierProvider<UserProvider>(
                create: (context) => UserProvider()),
            ChangeNotifierProvider<HomeProvider>(
                create: (context) => HomeProvider()),
            ChangeNotifierProvider<CategoryProvider>(
                create: (context) => CategoryProvider()),
            ChangeNotifierProvider<ProductDetailProvider>(
                create: (context) => ProductDetailProvider()),
            ChangeNotifierProvider<FavoriteProvider>(
                create: (context) => FavoriteProvider()),
            ChangeNotifierProvider<OrderProvider>(
                create: (context) => OrderProvider()),
            ChangeNotifierProvider<CartProvider>(
                create: (context) => CartProvider()),
          ],
          child: Sizer(
            builder: (context, orientation, deviceType) {
              return MaterialApp(
                //scaffoldMessengerKey: rootScaffoldMessengerKey,
                locale: _locale,
                supportedLocales: [
                  Locale("en", "US"),
                  Locale("zh", "CN"),
                  Locale("es", "ES"),
                  Locale("hi", "IN"),
                  Locale("ar", "DZ"),
                  Locale("ru", "RU"),
                  Locale("ja", "JP"),
                  Locale("de", "DE")
                ],
                localizationsDelegates: [
                  CountryLocalizations.delegate,
                  DemoLocalization.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                localeResolutionCallback: (locale, supportedLocales) {
                  for (var supportedLocale in supportedLocales) {
                    if (supportedLocale.languageCode == locale!.languageCode &&
                        supportedLocale.countryCode == locale.countryCode) {
                      return supportedLocale;
                    }
                  }
                  return supportedLocales.first;
                },
                title: appName,

                theme: ThemeData(
                  canvasColor: Theme.of(context).colorScheme.lightWhite,
                  cardColor: Theme.of(context).colorScheme.white,
                  dialogBackgroundColor: Theme.of(context).colorScheme.white,
                  iconTheme:
                      Theme.of(context).iconTheme.copyWith(color: colors.primary),
                  primarySwatch: colors.primary_app,
                  primaryColor: Theme.of(context).colorScheme.lightWhite,
                  fontFamily: 'opensans',
                  brightness: Brightness.light,
                  textTheme: TextTheme(
                          headline6: TextStyle(
                            color: Theme.of(context).colorScheme.fontColor,
                            fontWeight: FontWeight.w600,
                          ),
                          subtitle1: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold))
                      .apply(bodyColor: Theme.of(context).colorScheme.fontColor),
                ),
                debugShowCheckedModeBanner: false,
                initialRoute: '/',
                routes: {
                  // '/': (context) => Splash(),
                  '/': (context) => WelcomeOneView(),
                  '/home': (context) => Dashboard(),
                },
                darkTheme: ThemeData(
                  canvasColor: colors.darkColor,
                  cardColor: colors.darkColor2,
                  dialogBackgroundColor: colors.darkColor2,
                  primarySwatch: colors.primary_app,
                  primaryColor: colors.darkColor,
                  textSelectionTheme: TextSelectionThemeData(
                      cursorColor: colors.darkIcon,
                      selectionColor: colors.darkIcon,
                      selectionHandleColor: colors.darkIcon),
                  toggleableActiveColor: colors.primary,
                  fontFamily: 'opensans',
                  brightness: Brightness.dark,
                  accentColor: colors.darkIcon,
                  iconTheme:
                      Theme.of(context).iconTheme.copyWith(color: colors.secondary),
                  textTheme: TextTheme(
                          headline6: TextStyle(
                            color: Theme.of(context).colorScheme.fontColor,
                            fontWeight: FontWeight.w600,
                          ),
                          subtitle1: TextStyle(
                              color: Theme.of(context).colorScheme.fontColor,
                              fontWeight: FontWeight.bold))
                      .apply(bodyColor: Theme.of(context).colorScheme.fontColor),
                ),
                themeMode: themeNotifier.getThemeMode(),
              );
            }
          ));
    }
  }
}
class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext? context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}