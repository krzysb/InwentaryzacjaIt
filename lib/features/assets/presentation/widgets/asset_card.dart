import 'package:flutter/material.dart';

import '../../../dictionaries/domain/category.dart';
import '../../../dictionaries/domain/location.dart';
import '../../domain/asset.dart';
import '../../domain/asset_status.dart';

class AssetCard extends StatelessWidget {
  final Asset asset;
  final Category? category;
  final Location? location;
  final VoidCallback onTap;

  const AssetCard({
    super.key,
    required this.asset,
    required this.category,
    required this.location,
    required this.onTap,
  });

  Color _statusColor(BuildContext context) {
    switch (asset.status) {
      case AssetStatus.sprawny:
        return Colors.green;
      case AssetStatus.uszkodzony:
        return Colors.red;
      case AssetStatus.wNaprawie:
        return Colors.orange;
      case AssetStatus.wycofany:
        return Colors.grey;
      case AssetStatus.zaginiony:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _statusColor(context).withValues(alpha: 0.15),
          child: Icon(Icons.devices, color: _statusColor(context)),
        ),
        title: Text(asset.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            category?.name ?? asset.categoryId,
            location?.displayName ?? asset.locationId,
            if (asset.serialNumber != null && asset.serialNumber!.isNotEmpty) 'S/N: ${asset.serialNumber}',
          ].join(' • '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(asset.status.label, style: TextStyle(color: _statusColor(context), fontSize: 12)),
            if (asset.isIncomplete)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber),
              ),
          ],
        ),
      ),
    );
  }
}
