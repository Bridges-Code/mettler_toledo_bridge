import 'package:flutter_test/flutter_test.dart';

import 'package:mettler_toledo_bridge/mettler_toledo_bridge.dart';

void main() {
  test('parse continuous data', () {
    const line0 = '40    046   000';
    final data0 = parseContinuousData(line0);
    expect(data0.deciamlPointLocation, 2);
    expect(data0.netWeight, 0.46);
    expect(data0.grossWeight, 0.46);
    expect(data0.unit, MettlerToledoDataUnit.kg);
    expect(data0.isStable, true);

    const line1 = '41    144   046';
    final data1 = parseContinuousData(line1);
    expect(data1.deciamlPointLocation, 2);
    expect(data1.netWeight, 1.44);
    expect(data1.grossWeight, 1.9);
    expect(data1.tareWeight, 0.46);
    expect(data1.unit, MettlerToledoDataUnit.kg);
    expect(data1.isStable, true);

    const line2 = '49    072   046';
    final data2 = parseContinuousData(line2);
    expect(data2.netWeight, 0.72);
    expect(data2.isStable, false);

    const line3 = '1!!  1440   460';
    final data3 = parseContinuousData(line3);
    expect(data3.unit, MettlerToledoDataUnit.g);
    expect(data3.netWeight, 1440);
    expect(data3.tareWeight, 460);

    const line4 = '2!1  1448   450';
    final data4 = parseContinuousData(line4);
    expect(data4.isDataExpanded, true);
    expect(data4.netWeight, 1448);
  });
}
