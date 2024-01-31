import 'package:flutter/material.dart';
import 'package:inventool/locale/locale.dart';

class Tool {
  final int? id;
  final String tooltype;
  final bool? steel;
  final bool? stainless;
  final bool? castiron;
  final bool? aluminum;
  final bool? universal;
  final String? catnum;
  final String invnum;
  final String? unit; // da radiounit
  final String? grinded; // da
  final String? mfr;
  final String? holdertype;
  final String? tipdiamm;
  final String? tipdiainch;
  final num? shankdia;
  final String? pitch; //dropdown
  final num? neckdia; // da
  final num? tslotdp; // da
  final num? toollen; // da
  final num? splen; // da
  final num? worklen; // da
  final int? bladecnt; // da
  final String? tiptype; // da
  final String? tipsize; // da
  final String? material; // da
  final String? coating;
  final String? inserttype;
  final String? cabinet;
  final int? qty;
  final int? issued;
  final int? avail;
  final int? minqty;
  final String? secocab;
  final String? sandvikcab;
  final String? kennacab;
  final String? niagaracab;
  final int? extcab;
  final String? sourcetable;
  final String? subtype;

  Tool(
      {this.id,
      required this.tooltype,
      this.steel,
      this.stainless,
      this.castiron,
      this.aluminum,
      this.universal,
      required this.invnum,
      this.catnum,
      this.unit,
      this.grinded,
      this.mfr,
      this.holdertype,
      this.tipdiamm,
      this.tipdiainch,
      this.shankdia,
      this.pitch,
      this.neckdia,
      this.tslotdp,
      this.toollen,
      this.splen,
      this.worklen,
      this.bladecnt,
      this.tiptype,
      this.tipsize,
      this.material,
      this.coating,
      this.inserttype,
      this.cabinet,
      this.qty,
      this.issued,
      this.avail,
      this.minqty,
      this.secocab,
      this.sandvikcab,
      this.kennacab,
      this.niagaracab,
      this.extcab,
      this.sourcetable,
      this.subtype});

  String? materialParse() {
    List<String> materials = [];
    if (steel == true) materials.add('Steel');
    if (stainless == true) materials.add('Stainless');
    if (castiron == true) materials.add('Cast Iron');
    if (aluminum == true) materials.add('Aluminum');
    if (universal == true) materials.add('Universal');

    if (materials.isNotEmpty) {
      return materials.join(', ');
    } else {
      return null;
    }
  }

  String? parseLengthAndMaterial(BuildContext context) {
    List<String> details = [];

    if (material != null) {
      details.add('${context.localize('material')}: $material');
    }

    if (worklen != null) {
      details.add('${context.localize('worklen')}: $worklen mm');
    } else if (splen != null) {
      details.add('${context.localize('splen')}: $splen mm');
    }

    if (details.isNotEmpty) {
      return details.join(', ');
    } else {
      return null;
    }
  }

  String? parseTipdia() {
    String? tipdia;
    if (unit != null) {
      if (unit == "mm") {
        double value = double.tryParse(tipdiamm ?? '') ?? 0;
        tipdia = _trimTrailingZeros(value.toString());
      } else {
        double value = double.tryParse(tipdiainch ?? '') ?? 0;
        tipdia = _trimTrailingZeros(value.toStringAsFixed(4));
      }
    }
    return tipdia;
  }

  String _trimTrailingZeros(String numberString) {
    if (!numberString.contains('.')) return numberString;
    String trimmed = numberString.replaceAll(RegExp(r'0*$'), '');
    if (trimmed.endsWith('.')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }
}
