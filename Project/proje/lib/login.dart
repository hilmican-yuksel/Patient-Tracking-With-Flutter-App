import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hilmican_proje/main.dart';
import 'package:login_fresh/login_fresh.dart';
import 'package:fluttertoast/fluttertoast.dart';


class LoginPageNew extends StatefulWidget {
  //You have to create a list with the type of login's that you are going to import into your application

  @override
  _LoginPageNewState createState() => _LoginPageNewState();
}

class _LoginPageNewState extends State<LoginPageNew> {
  User _firebaseUser;       // Firebase paketinde bulunan User classı
  FToast fToast;

@override
  void initState() {
    fToast = FToast();
    fToast.init(context);

    Firebase.initializeApp().whenComplete(() { 
    setState(() {});
    var user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _firebaseUser = user;
      navigateToHomePage();
    }
  });
  
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(body: buildLoginFresh()));
  }

  LoginFresh buildLoginFresh() {
    List<LoginFreshTypeLoginModel> listLogin = [
      LoginFreshTypeLoginModel(
          callFunction: (BuildContext _buildContext) {
            // develop what they want the facebook to do when the user clicks
          },
          logo: TypeLogo.facebook),
      LoginFreshTypeLoginModel(
          callFunction: (BuildContext _buildContext) {
            // develop what they want the Google to do when the user clicks
          },
          logo: TypeLogo.google),
      LoginFreshTypeLoginModel(
          callFunction: (BuildContext _buildContext) {
            print("APPLE");
            // develop what they want the Apple to do when the user clicks
          },
          logo: TypeLogo.apple),
      LoginFreshTypeLoginModel(
          callFunction: (BuildContext _buildContext) {
            Navigator.of(_buildContext).push(MaterialPageRoute(
              builder: (_buildContext) => widgetLoginFreshUserAndPassword(),
            ));
          },
          logo: TypeLogo.userPassword),
    ];

    return LoginFresh(
      pathLogo: 'assets/logo.png',
      isExploreApp: true,
      functionExploreApp: () {
        // develop what they want the ExploreApp to do when the user clicks
      },
      isFooter: true,
      widgetFooter: this.widgetFooter(),
      typeLoginModel: listLogin,
      isSignUp: true,
      widgetSignUp: this.widgetLoginFreshSignUp(),
    );
  }

  Widget widgetLoginFreshUserAndPassword() {
    return LoginFreshUserAndPassword(
      callLogin: (BuildContext _context, Function isRequest, String user,
          String password) {
        isRequest(true);

        Future.delayed(Duration(seconds: 2), () {
          print('-------------- function call----------------');
          print(user);
          print(password);
          if (user == '') {
            // Custom Toast Position
    _showToast("Email adresini giriniz!");
          } else if (password == '') {
            _showToast("Şifrenizi giriniz!");
          } else {
            
            signInWithEmailAndPassword(
                                  user, password, _context);
          }
          print('--------------   end call   ----------------');

          isRequest(false);
        });
      },
      logo: './assets/logo_head.png',
      isFooter: true,
      widgetFooter: this.widgetFooter(),
      isResetPassword: false,
      widgetResetPassword: this.widgetResetPassword(),
      isSignUp: true,
      signUp: this.widgetLoginFreshSignUp(),
    );
  }
_showToast(String text) {
    Widget toast = Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        color: Colors.greenAccent,
        ),
        child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
            Icon(Icons.check),
            SizedBox(
            width: 12.0,
            ),
            Text(text),
        ],
        ),
    );


    fToast.showToast(
        child: toast,
        gravity: ToastGravity.CENTER,
        toastDuration: Duration(seconds: 2),
    );
}
  Widget widgetResetPassword() {
    return LoginFreshResetPassword(
      logo: 'assets/logo_head.png',
      funResetPassword:
          (BuildContext _context, Function isRequest, String email) {
        isRequest(true);

        Future.delayed(Duration(seconds: 2), () {
          print('-------------- function call----------------');
          print(email);
          print('--------------   end call   ----------------');
          isRequest(false);
        });
      },
      isFooter: true,
      widgetFooter: this.widgetFooter(),
    );
  }

  Widget widgetFooter() {
    return LoginFreshFooter(
      logo: 'assets/logo_footer.png',
      text: 'Power by',
      funFooterLogin: () {
        // develop what they want the footer to do when the user clicks
      },
    );
  }

  Widget widgetLoginFreshSignUp() {
    return LoginFreshSignUp(
        isFooter: true,
        widgetFooter: this.widgetFooter(),
        logo: 'assets/logo_head.png',
        funSignUp: (BuildContext _context, Function isRequest,
            SignUpModel signUpModel) {
          isRequest(true);

          print(signUpModel.email);
          print(signUpModel.password);
          print(signUpModel.repeatPassword);
          print(signUpModel.surname);
          print(signUpModel.name);
          if (signUpModel.email == '') {
            _showToast("Email adresinizi giriniz!");
          } else if (signUpModel.password == '') {
            _showToast("Şifrenizi giriniz!");
          } else {
            
            signUpWithEmailAndPassword(
                signUpModel.email, signUpModel.password, _context);
          }
          isRequest(false);
        });
  }

  void signUpWithEmailAndPassword(
      String email, String password, BuildContext context) async {
    FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password)
        .then((UserCredential user) {
      _firebaseUser = user.user;
      _showToast("Üyelik kaydı başarılı");
      navigateToHomePage();
    }).catchError((e) {
      Scaffold.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    });
  }
  void signInWithEmailAndPassword(
      String email, String password, BuildContext context) {
    FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password)
        .then((UserCredential user) {
      _firebaseUser = user.user;
      _showToast("Giriş başarılı");
      navigateToHomePage();
    }).catchError((e) {
      
    switch (e.message) {
      case 'There is no user record corresponding to this identifier. The user may have been deleted.':
        _showToast("Böyle bir kullanıcı bulunamadı");
        break;
      case 'The password is invalid or the user does not have a password.':
        _showToast("Kullanıcı adı veya Şifre yanlış");
        break;
      case 'A network error (such as timeout, interrupted connection or unreachable host) has occurred.':
        _showToast("Sunucuya ulaşılırken hata oluştu");
        break;
      default:
        _showToast("Sunucuya ulaşılırken hata oluştu");
    }
      
    });
  }
  void navigateToHomePage() {
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => HilmicanApp()));
  }
}
