import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../config/app_colors.dart';
import '../../models/service_item.dart';
import '../../services/service_catalog_service.dart';
import '../../widgets/skeleton_loader.dart';
import '../../widgets/rpm_gauge_loader.dart';

class ServicesRepairsScreen extends StatefulWidget {
  const ServicesRepairsScreen({super.key});

  @override
  State<ServicesRepairsScreen> createState() => _ServicesRepairsScreenState();
}

class _ServicesRepairsScreenState extends State<ServicesRepairsScreen> {
  String _selectedTab = 'All';
  final _searchCtrl = TextEditingController();
  List<ServiceCatalogItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchServices() async {
    setState(() => _loading = true);
    try {
      final res = await ServiceCatalogService.list(
        query: _searchCtrl.text.trim(),
        type: _selectedTab,
      );
      if (mounted) {
        setState(() {
          _items = res;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        Fluttertoast.showToast(msg: 'Failed to load services: $e');
      }
    }
  }

  void _showAddEditServiceSheet([ServiceCatalogItem? existingItem]) {
    final isEdit = existingItem != null;
    final nameCtrl = TextEditingController(text: isEdit ? existingItem.name : '');
    final priceCtrl = TextEditingController(text: isEdit ? existingItem.price.toStringAsFixed(0) : '');
    String type = isEdit ? (existingItem.type[0].toUpperCase() + existingItem.type.substring(1)) : 'Service';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Service / Repair' : 'Add New Service / Repair',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *', hintText: 'e.g. Chain Cleaning & Lube'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (₹) *', hintText: 'e.g. 150'),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text('Category: ', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Service'),
                    selected: type == 'Service',
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: type == 'Service' ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                    onSelected: (_) => setSheetState(() => type = 'Service'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Repair'),
                    selected: type == 'Repair',
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(color: type == 'Repair' ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                    onSelected: (_) => setSheetState(() => type = 'Repair'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: () async {
                    if (nameCtrl.text.trim().isEmpty || priceCtrl.text.trim().isEmpty) {
                      Fluttertoast.showToast(msg: 'Name and Price are required');
                      return;
                    }
                    final price = double.tryParse(priceCtrl.text.trim());
                    if (price == null) {
                      Fluttertoast.showToast(msg: 'Invalid price');
                      return;
                    }

                    Navigator.pop(ctx);
                    RpmGaugeLoader.show(context, statusMessages: ['Saving catalog item', 'Updating catalog', 'Almost ready']);
                    try {
                      if (isEdit) {
                        await ServiceCatalogService.update(existingItem.id, name: nameCtrl.text.trim(), price: price, type: type);
                        Fluttertoast.showToast(msg: 'Service updated');
                      } else {
                        await ServiceCatalogService.create(nameCtrl.text.trim(), price, type);
                        Fluttertoast.showToast(msg: 'New service added');
                      }
                      if (mounted) {
                        RpmGaugeLoader.hide(context);
                        _fetchServices();
                      }
                    } catch (e) {
                      if (mounted) RpmGaugeLoader.hide(context);
                      Fluttertoast.showToast(msg: 'Failed to save service: $e');
                    }
                  },
                  child: Text(isEdit ? 'Save Changes' : 'Add to Catalog', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteService(ServiceCatalogItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Service', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${item.name}" from catalog?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              RpmGaugeLoader.show(context, statusMessages: ['Removing service', 'Updating catalog']);
              try {
                await ServiceCatalogService.delete(item.id);
                if (mounted) {
                  RpmGaugeLoader.hide(context);
                  Fluttertoast.showToast(msg: 'Service removed');
                  _fetchServices();
                }
              } catch (e) {
                if (mounted) RpmGaugeLoader.hide(context);
                Fluttertoast.showToast(msg: 'Failed to delete service: $e');
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Services & Repairs', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _fetchServices,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search services or repairs',
                      prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchCtrl.clear();
                                _fetchServices();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.surface,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.cardBorder)),
                    ),
                    onChanged: (_) => _fetchServices(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ['All', 'Service', 'Repair'].map((tab) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(tab),
                        selected: _selectedTab == tab,
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: _selectedTab == tab ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
                        onSelected: (_) {
                          setState(() => _selectedTab = tab);
                          _fetchServices();
                        },
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: SkeletonListLoader(count: 5),
                    )
                  : _items.isEmpty
                      ? const Center(child: Text('No services or repairs found.', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final item = _items[index];
                            final isRepair = item.type.toLowerCase() == 'repair';

                            return Card(
                              color: AppColors.surface,
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: isRepair ? AppColors.warningBg : AppColors.primaryLight,
                                  child: Icon(
                                    isRepair ? Icons.build_outlined : Icons.handyman_outlined,
                                    color: isRepair ? AppColors.warningText : AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                                subtitle: Text(
                                  item.type[0].toUpperCase() + item.type.substring(1),
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                                      onPressed: () => _confirmDeleteService(item),
                                    ),
                                  ],
                                ),
                                onTap: () => _showAddEditServiceSheet(item),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Add Service / Repair', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _showAddEditServiceSheet(),
            ),
          ),
        ),
      ),
    );
  }
}
