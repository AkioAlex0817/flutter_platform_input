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
    this.controller,
    this.placeholder,
    this.textContentType,
    this.keyboardType = KeyboardType.defaultType,
    this.obsecureText = false,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.textAlign = TextAlign.start,
  }) : super(key: key);
  final TextEditingController? controller;
  final String? placeholder;
  final TextContentType? textContentType;
  final KeyboardType? keyboardType;
  final bool? obsecureText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final TextAlign? textAlign;

  @override
  UiTextFieldState createState() => UiTextFieldState();
}

class UiTextFieldState extends State<UiTextField> {
  MethodChannel? _channel;

  TextEditingController? _controller;
  TextEditingController get _effectiveController => widget.controller ?? (_controller ??= TextEditingController());

  FocusNode? _focusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_focusNode ??= FocusNode());

  @override void initState() {
    super.initState();

    if (widget.focusNode != null) {
      widget.focusNode!.addListener(() {
        if (widget.focusNode!.hasFocus) {
          _channel!.invokeMethod("focus");
        }
      });
    }

    if (widget.controller != null) {
      widget.controller!.addListener(() {
        _channel!.invokeMethod("setText", { "text": widget.controller!.text ?? "" });
      });
    }
  }

  void setFocus(){
    _channel!.invokeMethod("focus");
  }

  void setEmpty(){
    _channel!.invokeMethod("setText", {"text" : ""});
  }

  @override
  void dispose() {
    _controller?.dispose();
    _focusNode?.dispose();
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
  }

  Map<String, dynamic> _buildCreationParams() {
    return {
      "text": _effectiveController.text ?? "",
      "placeholder": widget.placeholder ?? "",
      "textContentType": widget.textContentType?.toString(),
      "keyboardType": widget.keyboardType?.toString(),
      "obsecureText": widget.obsecureText,
      "textAlign": widget.textAlign.toString()
    };
  }

  Future<bool?> _onMethodCall(MethodCall call) async {
    switch (call.method) {
      case "onChanged":
        final String text = call.arguments["text"];
        _onTextFieldChanged(text);
        return null;

      case "textFieldDidBeginEditing":
        _textFieldDidBeginEditing();
        return null;

      case "textFieldDidEndEditing":
      //final String text = call.arguments["text"];
      //_textFieldDidEndEditing(text);
        return null;
      case "onSubmitted":
        final String text = call.arguments["text"];
        _textFieldSubmitted(text);
    }

    throw MissingPluginException("UiTextField._onMethodCall: No handler for ${call.method}");
  }

  void _onTextFieldChanged(String? text) {
    if (text != null && widget.onChanged != null) {
      widget.onChanged!(text);
    }
  }

  void _textFieldSubmitted(String text){
    if(widget.onSubmitted != null){
      widget.onSubmitted!(text);
    }
  }

  // UITextFieldDelegate methods

  void _textFieldDidBeginEditing() {
    FocusScope.of(context).requestFocus(_effectiveFocusNode);
  }

  /// Editing stopped for the specified text field.
  void _textFieldDidEndEditing(String text) {
    if (widget.onSubmitted != null) {
      widget.onSubmitted!(text);
    }
  }
}