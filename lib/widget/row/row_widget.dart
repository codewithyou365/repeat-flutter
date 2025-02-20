import 'package:board_datetime_picker/board_datetime_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:repeat_flutter/common/date.dart';
import 'package:repeat_flutter/widget/dialog/msg_box.dart';

class RowWidget {
  static const double titleFontSize = 17;
  static const double rowHeight = 50;
  static const double paddingHorizontal = 8;

  static Widget buildMiddleText(String title, {bool main = true}) {
    var ts = const TextStyle(fontSize: titleFontSize);
    if (!main) {
      ts = const TextStyle(fontSize: titleFontSize, color: Colors.grey);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingHorizontal, vertical: paddingHorizontal),
      child: Text(
        title,
        style: ts,
      ),
    );
  }

  static Widget buildCupertinoPicker(String title, List<String> options, RxInt initialValue, [ValueChanged<int>? changed]) {
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
              width: 80.w,
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
