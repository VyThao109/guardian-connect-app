import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:guardian_connect_app/bloc/root_bloc.dart';
import 'package:guardian_connect_app/common/extensions/custom_theme_extension.dart';
import 'package:guardian_connect_app/common/extensions/font_sizes.dart';
import 'package:guardian_connect_app/presentations/widgets/button/common_button.dart';
import 'package:guardian_connect_app/presentations/widgets/snackbar/custom_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactModal extends StatefulWidget {
  const ContactModal({super.key});

  @override
  State<ContactModal> createState() => _ContactModalState();
}

class _ContactModalState extends State<ContactModal> {
  late TextEditingController _phoneController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: context.read<RootBloc>().state.companionPhoneNumber,
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> makePhoneCall() async {
    final phoneNumber = _phoneController.text.trim();
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);

    await launchUrl(launchUri, mode: LaunchMode.externalApplication);
  }

  // Bật chế độ edit
  void startEditing() {
    setState(() {
      _isEditing = true;
    });
  }

  void cancelEditing() {
    setState(() {
      _isEditing = false;
      _phoneController.text = context
          .read<RootBloc>()
          .state
          .companionPhoneNumber;
    });
  }

  void savePhoneNumber() {
    final newNumber = _phoneController.text.trim();

    if (newNumber.isEmpty) {
      CustomSnackbar.showSnackBar(
        context,
        "Something's wrong",
        "Phone number cannot be empty",
        AlertType.error,
      );
      return;
    }

    // Validate phone number (basic)
    if (!RegExp(r'^[0-9+\s()-]+$').hasMatch(newNumber)) {
      CustomSnackbar.showSnackBar(
        context,
        "Something's wrong",
        "Invalid phone number format",
        AlertType.error,
      );
      return;
    }

    context.read<RootBloc>().add(UpdateCompanionPhoneEvent(newNumber));
    setState(() {
      _isEditing = false;
    });

    Navigator.pop(context);

    CustomSnackbar.showSnackBar(
      context,
      "Thành công",
      "Đã cập nhật số người thân",
      AlertType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 20,
        children: [
          const Text(
            'Liên lạc với người thân',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: context.theme.grayBgColor ?? Colors.grey,
              borderRadius: BorderRadius.circular(4),
            ),
            child: TextField(
              controller: _phoneController,
              readOnly: !_isEditing,
              keyboardType: TextInputType.phone,
              style: TextStyle(
                fontSize: FontSizes.large,
                color: context.theme.black,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
                suffixIcon: !_isEditing
                    ? IconButton(
                        icon: Icon(
                          Feather.edit_3,
                          color: context.theme.black,
                          size: 20,
                        ),
                        onPressed: startEditing,
                        tooltip: 'Cập nhật số điện thoại',
                      )
                    : null,
                hintText: 'Nhập số điện thoại',
                border: InputBorder.none,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]')),
              ],
            ),
          ),
          _isEditing
              ? buildEditButtons(context)
              : SizedBox(
                  width: double.infinity,
                  child: CommonButton(
                    label: 'Gọi ngay',
                    onPressed: makePhoneCall,
                  ),
                ),
        ],
      ),
    );
  }

  Widget buildEditButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 20,
      children: [
        Expanded(
          child: TextButton(
            onPressed: cancelEditing,
            style: TextButton.styleFrom(
              backgroundColor: context.theme.blue300,
              foregroundColor: context.theme.blue,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: context.theme.blue500 ?? Colors.lightBlue,
                  width: 1.5,
                ),
              ),
            ),
            child: Text("Hủy"),
          ),
        ),
        Expanded(
          child: CommonButton(label: "Lưu", onPressed: savePhoneNumber),
        ),
      ],
    );
  }
}
