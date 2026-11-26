import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:material_ui/material_ui.dart';

/// Bottom padding that keeps the last item clear of the floating nav bar.
EdgeInsets libraryListPadding(BuildContext context) => EdgeInsets.only(
  top: 8.h,
  bottom: MediaQuery.paddingOf(context).bottom + 16.h,
);
