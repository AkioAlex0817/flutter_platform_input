import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

enum TextContentType {
  name,
  namePrefix,
  givenName,
  middleName,
  familyName,
  nameSuffix,
  nickname,
  jobTitle,
  organizationName,
  location,
  fullStreetAddress,
  streetAddressLine1,
  streetAddressLine2,
  addressCity,
  addressState,
  addressCityAndState,
  sublocality,
  countryName,
  postalCode,
  telephoneNumber,
  emailAddress,
  url,
  creditCardNumber,
  username,
  password,
  newPassword,          // iOS12+
  oneTimeCode           // iOS12+
}

enum KeyboardType {
  /// Default type for the current input method.
  defaultType,
  /// Displays a keyboard which can enter ASCII characters
  asciiCapable,
  /// Numbers and assorted punctuation.
  numbersAndPunctuation,
  /// A type optimized for URL entry (shows . / .com prominently).
  url,
  /// A number pad with locale-appropriate digits (0-9, ۰-۹, ०-९, etc.). Suitable for PIN
  numberPad,
  /// A phone pad (1-9, *, 0, #, with letters under the numbers).
  phonePad,
  /// A type optimized for entering a person's name or phone number.
  namePhonePad,
  /// A type optimized for multiple email address entry (shows space @ . prominently).
  emailAddress,
  /// A number pad with a decimal point. iOS 4.1+.
  decimalPad,
  /// A type optimized for twitter text entry (easy access to @ #).
  twitter,
  /// A default keyboard type with URL-oriented addition (shows space . prominently).
  webSearch,
  // A number pad (0-9) that will always be ASCII digits. Falls back to KeyboardType.numberPad below iOS 10.
  asciiCapableNumberPad
}

class UiTextField extends StatefulWidget {
  const UiTextField({
    Key? key,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
  }) : super(key: key);

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final FocusNode focusNode;

  @override
  UiTextFieldState createState() => UiTextFieldState();
}

class UiTextFieldState extends State<UiTextField> {
  late MethodChannel _channel;
  TextEditingController get _effectiveController =>  TextEditingController();
  FocusNode get _effectiveFocusNode => widget.focusNode;

  @override void initState() {
    super.initState();

    widget.focusNode.addListener(() {
      if (!widget.focusNode.hasFocus) {
        _channel.invokeMethod("focus");
      }
    });
  }

  void setFocus(){
    _channel.invokeMethod("focus");
  }

  void setEmpty(){
    _channel.invokeMethod("setText", {"text" : ""});
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
          minWidth: 31,
          minHeight: 31,
          maxHeight: 31
      ),
      child: UiKitView(
          viewType: "dev.gilder.tom/uitextfield",
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: _buildCreationParams(),
          onPlatformViewCreated: _createMethodChannel
      ),
    );
  }

  void _createMethodChannel(int nativeViewId) {
    _channel = MethodChannel("dev.gilder.tom/uitextfield_$nativeViewId")
      ..setMethodCallHandler(_onMethodCall);
    _channel.invokeMethod("focus");
  }

  Map<String, dynamic> _buildCreationParams() {
    return {
      "text": _effectiveController.text,
      "placeholder": "PlaceHolder",
      "textContentType": TextContentType.telephoneNumber.toString(),
      "keyboardType": KeyboardType.defaultType.toString(),
      "obsecureText": false,
      "textAlign": TextAlign.start.toString()
    };
  }

  Future<bool> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case "onChanged":
        final String text = call.arguments["text"];
        _onTextFieldChanged(text);
        return false;

      case "textFieldDidBeginEditing":
        _textFieldDidBeginEditing();
        return false;

      case "textFieldDidEndEditing":
        return false;
      case "onSubmitted":
        final String text = call.arguments["text"];
        _textFieldSubmitted(text);
        return false;
    }

    throw MissingPluginException("UiTextField._onMethodCall: No handler for ${call.method}");
  }

  void _onTextFieldChanged(String text) {
    widget.onChanged(text);
  }

  void _textFieldSubmitted(String text){
    widget.onSubmitted(text);
  }

  // UITextFieldDelegate methods

  void _textFieldDidBeginEditing() {
    FocusScope.of(context).requestFocus(_effectiveFocusNode);
  }

  /// Editing stopped for the specified text field.
  void _textFieldDidEndEditing(String text) {
    widget.onSubmitted(text);
  }
}