import 'package:flutter/material.dart';
import 'package:inventool/models/tool.dart';
import 'package:inventool/database.dart';
import 'package:inventool/widgets/toast_util.dart';
import 'package:inventool/main.dart';
import 'package:inventool/utils/app_theme.dart';
import 'package:inventool/locale/locale.dart';

class InsertToolDialog extends StatelessWidget {
  final Tool newTool;
  final DatabaseHelper databaseHelper;

  Widget boldText(BuildContext context, String label, String value) {
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: <TextSpan>[
          TextSpan(
            text: '$label:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          TextSpan(text: ' $value'),
        ],
      ),
    );
  }

  InsertToolDialog({
    required this.newTool,
    required this.databaseHelper,
  });

  @override
  Widget build(BuildContext context) {
    final toast = ToastUtil(context, MyApp.navigatorKey);
    return AlertDialog(
      title: Text('${context.localize('insertooldialogtitle')}'),
      content: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  boldText(
                      context, '${context.localize('mfr')}', newTool.mfr ?? ''),
                  boldText(context, '${context.localize('materials')}',
                      newTool.materialParse() ?? ''),
                  boldText(context, '${context.localize('catnum')}',
                      newTool.catnum ?? ''),
                  boldText(
                      context, '${context.localize('invnum')}', newTool.invnum),
                  boldText(context, '${context.localize('unit')}',
                      newTool.unit ?? ''),
                  boldText(context, '${context.localize('tipdia')}',
                      newTool.parseTipdia() ?? ''),
                  boldText(context, '${context.localize('worklen')}',
                      newTool.worklen.toString()),
                  boldText(context, '${context.localize('bladecnt')}',
                      newTool.bladecnt.toString()),
                  boldText(context, '${context.localize('tiptype')}',
                      newTool.tiptype ?? ''),
                  boldText(context, '${context.localize('tipsize')}',
                      newTool.tipsize ?? ''),
                  boldText(context, '${context.localize('material')}',
                      newTool.material ?? ''),
                  boldText(context, '${context.localize('grinded')}',
                      newTool.grinded ?? ''),
                  boldText(context, '${context.localize('holdertype')}',
                      newTool.holdertype.toString()),
                  boldText(context, '${context.localize('shankdia')}',
                      newTool.shankdia.toString()),
                  boldText(context, '${context.localize('pitch')}',
                      newTool.pitch.toString()),
                  boldText(context, '${context.localize('neckdia')}',
                      newTool.neckdia.toString()),
                  boldText(context, '${context.localize('tslotdp')}',
                      newTool.tslotdp.toString()),
                  boldText(context, '${context.localize('toollen')}',
                      newTool.toollen.toString()),
                  boldText(context, '${context.localize('shanklen')}',
                      newTool.shankdia.toString()),
                ],
              ),
              const SizedBox(width: 100),
              ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 360),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      boldText(context, '${context.localize('coating')}',
                          newTool.coating ?? ''),
                      boldText(context, context.localize('coating'),
                          newTool.inserttype ?? ''),
                      boldText(context, context.localize('cabinet'),
                          newTool.cabinet ?? ''),
                      boldText(context, context.localize('qty'),
                          newTool.qty.toString()),
                      boldText(context, context.localize('issued'),
                          newTool.issued.toString()),
                      boldText(context, context.localize('avail'),
                          newTool.avail.toString()),
                      boldText(context, context.localize('minqty'),
                          newTool.minqty.toString()),
                      boldText(context, context.localize('ftscab'),
                          newTool.ftscab.toString()),
                      boldText(context, context.localize('strcab'),
                          newTool.strcab.toString()),
                      boldText(context, context.localize('pfrcab'),
                          newTool.pfrcab.toString()),
                      boldText(context, context.localize('mitsucab'),
                          newTool.mitsucab.toString()),
                      boldText(context, context.localize('extcab'),
                          newTool.extcab.toString()),
                    ],
                  )),
            ],
          ),
          const SizedBox(height: 50),
          Align(
              alignment: Alignment.topCenter,
              child: Text(
                context.localize('inserttooldialogprompt'),
              ))
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            databaseHelper.insertTool(newTool);
            Navigator.of(context).pop();
            toast.showToast(
              context.localize('toastinsertedsuccessfully'),
              bgColor: AppTheme.toastColor(context),
            );
          },
          child: Text(context.localize('buttonyes')),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(context.localize('buttonno')),
        ),
      ],
    );
  }
}
