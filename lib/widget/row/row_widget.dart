import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/i18n/i18n_key.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

class Button {
  VoidCallback? onPressed;
  final String title;
  RxBool enable = true.obs;

  Button(this.title, [this.onPressed]);
}

class RowWidget {
  static const double titleFontSize = 17;
  static const double rowHeight = 50;
  static const double dividerHeight = 16;
  static const double paddingHorizontal = 8;
  static const double paddingVertical = 4;

  static Widget buildTabs(List<String> tabTitles, TabController? tabController, {Function(int)? onTap}) {
    if (tabController == null) {
      return const SizedBox(); // Prevent rendering if controller is null
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
      child: SizedBox(
        height: rowHeight,
        child: TabBar(
          controller: tabController,
          onTap: onTap,
          tabs: tabTitles.map((title) => Tab(text: title)).toList(),
          labelStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 15),
          indicatorSize: TabBarIndicatorSize.tab,
        ),
      ),
    );
  }

  static Widget buildButtons(
    List<Button> buttons,
  ) {
    List<Widget> children = [];
    for (var i = 0; i < buttons.length; i++) {
      if (i != 0) {
        children.add(const Spacer());
      }
      children.add(Obx(() {
        final theme = Theme.of(Get.context!);
        return TextButton(
          onPressed: buttons[i].enable.value
              ? (buttons[i].onPressed ??
                  () {
                    Get.back();
                  })
              : null,
          child: Text(
            buttons[i].title,
            style: TextStyle(
              fontSize: 16,
              color: buttons[i].enable.value ? theme.colorScheme.primary : theme.colorScheme.onSurface.withValues(alpha: 0.38),
            ),
          ),
        );
      }));
    }
    return Row(
      children: children,
    );
  }

  static Widget buildYesOrNo({
    VoidCallback? yes,
    String? yesBtnTitle,
    VoidCallback? no,
    String? noBtnTitle,
  }) {
    return Row(
      children: [
        TextButton(
          child: Text(noBtnTitle ?? I18nKey.btnCancel.tr),
          onPressed: () {
            if (no != null) {
              no();
            } else {
              Get.back();
            }
          },
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            if (yes != null) {
              yes();
            } else {
              Get.back();
            }
          },
          child: Text(yesBtnTitle ?? I18nKey.btnOk.tr),
        ),
      ],
    );
  }

  static Widget buildMiddleText(String title, {bool main = true}) {
    var ts = const TextStyle(fontSize: titleFontSize);
    if (!main) {
      ts = const TextStyle(fontSize: titleFontSize, color: Colors.grey);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingVertical),
      child: Text(
        title,
        style: ts,
      ),
    );
  }

  static Widget buildCard(Widget w) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingVertical),
      child: Card(
        color: Theme.of(Get.context!).secondaryHeaderColor,
        child: w,
      ),
    );
  }

  static Widget buildEditText(TextEditingController textController, {FocusNode? focusNode, int? maxLines, int? minLines, String? decoration}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingVertical),
      child: TextFormField(
        controller: textController,
        maxLines: maxLines,
        minLines: minLines,
        autofocus: true,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: decoration,
        ),
      ),
    );
  }

  static Widget buildQrCode(String value, [double? width]) {
    Color color = Colors.black;
    double size = 280.w;
    if (width != null) {
      size = width;
    }
    if (Get.context != null) {
      color = Theme.of(Get.context!).brightness == Brightness.dark ? color = Colors.white : Colors.black;
    }
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: QrImageView(
          data: value,
          eyeStyle: QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: color,
          ),
          dataModuleStyle: QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: color,
          ),
          version: QrVersions.auto,
          size: size,
        ),
      ),
    );
  }

  static Widget buildCupertinoPicker(String title, List<String> options, RxInt initialValue, {ValueChanged<int>? changed, double? pickWidth}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(paddingHorizontal, 0, 0, 0),
      child: SizedBox(
        height: rowHeight,
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: titleFontSize),
            ),
            const Spacer(),
            SizedBox(
              width: pickWidth ?? 80.w,
              height: 64,
              child: CupertinoPicker(
                scrollController: FixedExtentScrollController(initialItem: initialValue.value),
                itemExtent: 32.0,
                onSelectedItemChanged: changed,
                children: List.generate(options.length, (index) {
                  return Center(
                      child: Text(
                    options[index],
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.normal),
                  ));
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildSearch(RxString value, TextEditingController controller, {FocusNode? focusNode, VoidCallback? onClose, VoidCallback? onSearch}) {
    controller.addListener(() {
      value.value = controller.text;
    });

    return SizedBox(
      height: rowHeight,
      child: Row(
        children: [
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(Get.context!).secondaryHeaderColor,
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                textAlignVertical: TextAlignVertical.center,
                onSubmitted: (_) {
                  if (onSearch != null) {
                    onSearch();
                  }
                },
                decoration: InputDecoration(
                  hintText: I18nKey.labelSearch.tr,
                  isCollapsed: true,
                  contentPadding: const EdgeInsets.only(bottom: 3),
                  border: InputBorder.none,
                  suffix: Obx(() {
                    return value.value.isNotEmpty
                        ? GestureDetector(
                            child: const Text("×", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            onTap: () {
                              value.value = '';
                              if (onSearch != null) {
                                onSearch();
                              }
                              controller.clear();
                            },
                          )
                        : const SizedBox(height: 24);
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildText(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
      child: SizedBox(
        height: rowHeight,
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: titleFontSize),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
              child: Text(
                value,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget buildSwitch(String title, RxBool value, [Function(bool)? set]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
      child: SizedBox(
        height: rowHeight,
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: titleFontSize),
            ),
            const Spacer(),
            Obx(() {
              return Switch(value: value.value, onChanged: set != null ? (v) => set(v) : (v) => {value.value = v});
            }),
          ],
        ),
      ),
    );
  }

  static Widget buildWidgetsWithTitle(String title, List<Widget> buttons) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
      child: SizedBox(
        height: rowHeight,
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: titleFontSize),
            ),
            const Spacer(),
            ...buttons,
          ],
        ),
      ),
    );
  }

  static Widget buildDividerWithoutColor() {
    return const Divider();
  }

  static Widget buildDivider() {
    return const Divider(color: Colors.grey);
  }

  static Widget buildDateWithEdit(String title, RxInt value, BuildContext context) {
    return buildTextWithEdit(
      title,
      value,
      onTap: () async {
        var result = await showBoardDateTimePicker(
          initialDate: Date(value.value).toDateTime(),
          context: context,
          pickerType: DateTimePickerType.date,
          options: const BoardDateTimeOptions(showDateButton: false),
        );
        if (result == null) {
          return;
        }
        value.value = Date.from(result).value;
      },
      format: (Rx value) {
        return Date(value.value).format();
      },
    );
  }

  static Widget buildTextWithEdit(
    String title,
    Rx value, {
    GestureTapCallback? onTap,
    InputType? inputType,
    VoidCallback? yes,
    String Function(Rx)? format,
  }) {
    var showValue = value.value.toString();
    if (format != null) {
      showValue = format(value);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
      child: SizedBox(
        height: rowHeight,
        child: Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: titleFontSize),
            ),
            const Spacer(),
            InkWell(
              onTap: () {
                if (onTap == null) {
                  MsgBox.strInputWithYesOrNo(value, title, "", inputType: inputType, yes: yes);
                } else {
                  onTap();
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey, width: 2.0),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      showValue,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 5),
                    const Icon(Icons.edit),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
