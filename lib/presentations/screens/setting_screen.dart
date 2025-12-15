import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:guardian_connect_app/bloc/root_bloc.dart';
import 'package:guardian_connect_app/common/extensions/custom_theme_extension.dart';
import 'package:guardian_connect_app/common/extensions/font_sizes.dart';
import 'package:guardian_connect_app/presentations/widgets/button/common_button.dart';
import 'package:guardian_connect_app/presentations/widgets/button/custom_switch.dart';
import 'package:guardian_connect_app/presentations/widgets/snackbar/custom_snackbar.dart';
import 'package:guardian_connect_app/core/services/web_rtc_service.dart';

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RootBloc, RootState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: context.theme.whiteBgColor,
          appBar: AppBar(
            backgroundColor: context.theme.primaryColor,
            elevation: 0,
            toolbarHeight: 80,
            title: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Cài đặt',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: FontSizes.extraLarge,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            centerTitle: true,
            leading: InkWell(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Feather.arrow_left, color: Colors.white),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // GROUP 1: KẾT NỐI
              _buildSectionHeader(context, "TRẠNG THÁI HỆ THỐNG"),
              _buildConnectionControlCard(context, state),

              const SizedBox(height: 24),

              _buildSectionHeader(context, "KẾT NỐI THIẾT BỊ"),
              _buildSettingsGroup(
                children: [
                  _buildSettingTile(
                    context,
                    icon: Feather.wifi,
                    title: "Địa chỉ kết nối (IP/Domain)",
                    subtitle: state.deviceIp,
                    iconColor: context.theme.primaryColor ?? Colors.blue,
                    onTap: () => _showEditBottomSheet(
                      context,
                      title: "Cập nhật địa chỉ",
                      currentValue: state.deviceIp,
                      inputType: TextInputType.url,
                      hint: "VD: 192.168.1.10 hoặc my-app.ngrok.io",
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Địa chỉ không được để trống";
                        }

                        // 1. SỬA REGEX IP: Thêm đoạn (?:http:\/\/|https:\/\/)? ở đầu
                        // Để chấp nhận cả "192.168.1.1" và "http://192.168.1.1"
                        final ipRegex = RegExp(
                          r'^(?:http:\/\/|https:\/\/)?(?:[0-9]{1,3}\.){3}[0-9]{1,3}(?::\d+)?$',
                        );

                        // Regex Domain (Giữ nguyên)
                        final domainRegex = RegExp(
                          r'^(http:\/\/|https:\/\/)?([a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}(:\d+)?(\/.*)?$',
                        );

                        final isLocalhost = value.contains('localhost');

                        if (!ipRegex.hasMatch(value) &&
                            !domainRegex.hasMatch(value) &&
                            !isLocalhost) {
                          return "Địa chỉ IP hoặc tên miền không hợp lệ";
                        }

                        return null;
                      },
                      onSave: (val) {
                        String formattedUrl = val.trim();

                        // Xóa dấu / ở cuối
                        if (formattedUrl.endsWith("/")) {
                          formattedUrl = formattedUrl.substring(
                            0,
                            formattedUrl.length - 1,
                          );
                        }

                        // --- LOGIC XỬ LÝ MỚI ---

                        // Bước 1: Xác định xem đây có phải là IP không (bỏ qua http/https để check)
                        // Loại bỏ protocol tạm thời để kiểm tra format số
                        String rawUrl = formattedUrl.replaceFirst(
                          RegExp(r'^https?:\/\/'),
                          '',
                        );

                        // Regex check IP thuần (vd: 192.168.1.1 hoặc 192.168.1.1:8000)
                        final ipCheckRegex = RegExp(
                          r'^(?:[0-9]{1,3}\.){3}[0-9]{1,3}(?::\d+)?$',
                        );
                        bool isIp = ipCheckRegex.hasMatch(rawUrl);

                        if (isIp) {
                          // --- XỬ LÝ TRƯỜNG HỢP LÀ IP ---

                          // 1. Kiểm tra và thêm PORT :8000 nếu chưa có
                          if (!rawUrl.contains(':')) {
                            rawUrl = '$rawUrl:8000';
                          }

                          // 2. Đảm bảo Protocol là HTTP (IP thường dùng http)
                          // Nếu user nhập https thì giữ nguyên, nếu không có gì thì thêm http
                          if (formattedUrl.startsWith("https://")) {
                            formattedUrl = "https://$rawUrl";
                          } else {
                            formattedUrl = "http://$rawUrl";
                          }
                        } else {
                          // --- XỬ LÝ TRƯỜNG HỢP LÀ DOMAIN/NGROK ---

                          // Nếu chưa có protocol -> Thêm https
                          bool hasProtocol =
                              formattedUrl.startsWith("http://") ||
                              formattedUrl.startsWith("https://");
                          if (!hasProtocol) {
                            formattedUrl = "https://$formattedUrl";
                          }
                        }

                        // Lưu vào Bloc
                        context.read<RootBloc>().add(
                          UpdateDeviceIpEvent(formattedUrl),
                        );

                        CustomSnackbar.showSnackBar(
                          context,
                          "Thành công",
                          "Đã cập nhật: $formattedUrl",
                          AlertType.success,
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // GROUP 2: LIÊN HỆ & SOS
              _buildSectionHeader(context, "LIÊN HỆ KHẨN CẤP"),
              _buildSettingsGroup(
                children: [
                  _buildSettingTile(
                    context,
                    icon: Feather.phone,
                    title: "Số điện thoại người thân",
                    subtitle: state.companionPhoneNumber.isEmpty
                        ? "Chưa thiết lập"
                        : state.companionPhoneNumber,
                    iconColor: context.theme.green ?? Colors.green,
                    onTap: () => _showEditBottomSheet(
                      context,
                      title: "Số ĐT người thân",
                      currentValue: state.companionPhoneNumber,
                      inputType: TextInputType.phone,
                      validator: (value) {
                        if ((value ?? '').length < 10) {
                          return "Số điện thoại không hợp lệ";
                        }
                        return null;
                      },
                      onSave: (val) {
                        context.read<RootBloc>().add(
                          UpdateCompanionPhoneEvent(val),
                        );
                        CustomSnackbar.showSnackBar(
                          context,
                          "Thành công",
                          "Đã cập nhật số người thân",
                          AlertType.success,
                        );
                      },
                    ),
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.5,
                    color: Colors.grey[200],
                    indent: 60,
                  ),
                  _buildSettingTile(
                    context,
                    icon: MaterialCommunityIcons.ambulance,
                    title: "Đầu số cấp cứu",
                    subtitle: state.emergencyPhoneNumber,
                    iconColor: context.theme.red ?? Colors.red,
                    onTap: () => _showEditBottomSheet(
                      context,
                      title: "Đầu số cấp cứu",
                      currentValue: state.emergencyPhoneNumber,
                      inputType: TextInputType.number,
                      validator: (value) => (value?.isEmpty ?? true)
                          ? "Không được để trống"
                          : null,
                      onSave: (val) {
                        context.read<RootBloc>().add(
                          UpdateEmergencyPhoneEvent(val),
                        );
                        CustomSnackbar.showSnackBar(
                          context,
                          "Thành công",
                          "Đã cập nhật số cấp cứu",
                          AlertType.success,
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // GROUP 3: THÔNG BÁO
              _buildSectionHeader(context, "THÔNG BÁO"),
              _buildSettingsGroup(
                children: [
                  _buildSwitchTile(
                    context,
                    icon: Feather.bell,
                    title: "Nhận cảnh báo SOS",
                    subtitle: "Phát âm thanh khi nhận tín hiệu",
                    value: state.isSosNotificationEnabled,
                    iconColor: Colors.orange,
                    onChanged: (val) {
                      context.read<RootBloc>().add(
                        ToggleSosNotificationSettingEvent(val),
                      );

                      CustomSnackbar.showSnackBar(
                        context,
                        "Thành công",
                        val
                            ? "Đã bật nhận cảnh báo SOS"
                            : "Đã tắt cảnh báo SOS",
                        AlertType.success,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildConnectionControlCard(BuildContext context, RootState state) {
    final status = state.connectionStatus;
    final isConnected = status == ConnectionStatus.connected;
    final isConnecting = status == ConnectionStatus.connecting;
    final isFailed = status == ConnectionStatus.failed;

    // Cấu hình màu sắc và text theo trạng thái
    Color statusColor;
    String statusText;
    IconData statusIcon;
    String statusDetail;

    if (isConnected) {
      statusColor = context.theme.green ?? Colors.green;
      statusText = "Đang trực tuyến";
      statusDetail = "Kết nối ổn định";
      statusIcon = Feather.check_circle;
    } else if (isConnecting) {
      statusColor = Colors.orange;
      statusText = "Đang kết nối...";
      statusDetail = "Đang thử liên lạc với thiết bị";
      statusIcon = Feather.loader;
    } else if (isFailed) {
      statusColor = context.theme.red ?? Colors.red;
      statusText = "Kết nối thất bại";
      statusDetail = "Kiểm tra lại IP hoặc mạng Wifi";
      statusIcon = Feather.alert_circle;
    } else {
      statusColor = Colors.grey;
      statusText = "Đã ngắt kết nối";
      statusDetail = "Nhấn kết nối để bắt đầu";
      statusIcon = Feather.x_circle;
    }

    return _buildSettingsGroup(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withAlpha(25),
                      shape: BoxShape.circle,
                    ),
                    child: isConnecting
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: statusColor,
                            ),
                          )
                        : Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          statusDetail,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Divider(height: 1, thickness: 0.5, color: Colors.grey[200]),
              const SizedBox(height: 12),

              // Phần nút bấm hành động
              Row(
                children: [
                  Expanded(
                    child: isConnected
                        ? TextButton.icon(
                            onPressed: () {
                              context.read<RootBloc>().add(
                                const DisconnectDeviceEvent(),
                              );
                            },
                            icon: const Icon(Feather.power, size: 18),
                            style: TextButton.styleFrom(
                              foregroundColor: context.theme.red,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: context.theme.red ?? Colors.red,
                                  width: 1.5,
                                ),
                              ),
                            ),
                            label: Text("Ngắt kết nối"),
                          )
                        : CommonButton(
                            label: isFailed
                                ? "Thử kết nối lại"
                                : "Kết nối ngay",
                            icon: isFailed ? Feather.refresh_cw : Feather.link,
                            onPressed: isConnecting
                                ? null
                                : () {
                                    context.read<RootBloc>().add(
                                      const ConnectDeviceEvent(),
                                    );
                                  },
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsGroup({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Feather.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Color iconColor,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
          CustomSwitch(
            value: value,
            activeColor: context.theme.primaryColor ?? Colors.blue,
            activeIcon: Icons.notifications_active_rounded, // Icon khi bật
            inactiveIcon: Icons.notifications_off_rounded, // Icon khi tắt
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // --- SMART UX FUNCTIONS --

  void _showEditBottomSheet(
    BuildContext context, {
    required String title,
    required String currentValue,
    required Function(String) onSave,
    String? hint,
    TextInputType inputType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    final TextEditingController controller = TextEditingController(
      text: currentValue,
    );
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Để đẩy lên khi có bàn phím
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  keyboardType: inputType,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: hint,
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  validator: validator,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: CommonButton(
                    label: "Lưu thay đổi",
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        onSave(controller.text);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
