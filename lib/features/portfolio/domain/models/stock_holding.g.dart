// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_holding.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StockHoldingAdapter extends TypeAdapter<StockHolding> {
  @override
  final int typeId = 0;

  @override
  StockHolding read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StockHolding(
      id: fields[0] as String,
      symbol: fields[1] as String,
      name: fields[2] as String,
      quantity: fields[3] as double,
      averageBuyPrice: fields[4] as double,
      addedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StockHolding obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.symbol)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.averageBuyPrice)
      ..writeByte(5)
      ..write(obj.addedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockHoldingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
