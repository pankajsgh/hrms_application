import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomDropdown<T> extends StatefulWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final IconData? icon;
  final String Function(T)? searchText;
  final String? hint;
  final bool enabled;
  final double popupMaxHeight;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
    this.searchText,
    this.hint,
    this.enabled = true,
    this.popupMaxHeight = 260,
  });

  @override
  State<CustomDropdown<T>> createState() =>
      _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController =
  TextEditingController();
  final FocusNode _fieldFocus = FocusNode();
  final FocusNode _searchFocus = FocusNode();

  OverlayEntry? _overlayEntry;

  bool _isOpen = false;
  bool _isHovered = false;
  int _highlightedIndex = -1;

  List<DropdownMenuItem<T>> get _filteredItems {
    final query = _searchController.text.toLowerCase().trim();

    if (query.isEmpty || widget.searchText == null) {
      return widget.items;
    }

    return widget.items.where((item) {
      if (item.value == null) return false;

      return widget.searchText!(item.value!)
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  DropdownMenuItem<T>? get _selectedItem {
    for (final item in widget.items) {
      if (item.value == widget.value) return item;
    }
    return null;
  }

  @override
  void dispose() {
    _removeOverlay(updateState: false);
    _searchController.dispose();
    _fieldFocus.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleDropdown() {
    if (!widget.enabled) return;

    if (_isOpen) {
      _closeDropdown();
    } else {
      _openDropdown();
    }
  }

  void _openDropdown() {
    if (_isOpen) return;

    _searchController.clear();
    _highlightedIndex = -1;

    _overlayEntry = _createOverlay();

    Overlay.of(context).insert(_overlayEntry!);

    setState(() => _isOpen = true);
  }

  void _closeDropdown() {
    _removeOverlay();

    if (mounted) {
      setState(() => _isOpen = false);
    }
  }

  void _removeOverlay({bool updateState = true}) {
    _overlayEntry?.remove();
    _overlayEntry = null;

    if (updateState && mounted && _isOpen) {
      setState(() => _isOpen = false);
    }
  }

  void _selectItem(T? value) {
    widget.onChanged(value);
    _closeDropdown();
    _fieldFocus.requestFocus();
  }

  void _moveHighlight(int direction) {
    final items = _filteredItems;

    if (items.isEmpty) return;

    setState(() {
      if (_highlightedIndex == -1) {
        _highlightedIndex =
        direction > 0 ? 0 : items.length - 1;
      } else {
        _highlightedIndex =
            (_highlightedIndex + direction).clamp(
              0,
              items.length - 1,
            );
      }
    });

    _overlayEntry?.markNeedsBuild();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (!_isOpen || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      _closeDropdown();
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveHighlight(1);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveHighlight(-1);
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      final items = _filteredItems;

      if (_highlightedIndex >= 0 &&
          _highlightedIndex < items.length) {
        _selectItem(items[_highlightedIndex].value);
      }

      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  OverlayEntry _createOverlay() {
    return OverlayEntry(
      builder: (overlayContext) {
        final theme = Theme.of(context);
        final renderBox = context.findRenderObject() as RenderBox;
        final size = renderBox.size;

        final screenHeight = MediaQuery.of(context).size.height;
        final fieldPosition =
        renderBox.localToGlobal(Offset.zero);

        final spaceBelow =
            screenHeight - fieldPosition.dy - size.height - 16;

        final openAbove =
            spaceBelow < widget.popupMaxHeight &&
                fieldPosition.dy > spaceBelow;

        final availableHeight = openAbove
            ? fieldPosition.dy - 16
            : spaceBelow;

        final popupHeight = availableHeight
            .clamp(80.0, widget.popupMaxHeight)
            .toDouble();

        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _closeDropdown,
                child: const SizedBox.expand(),
              ),
            ),

            Positioned(
              width: size.width,
              child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                targetAnchor: openAbove
                    ? Alignment.topLeft
                    : Alignment.bottomLeft,
                followerAnchor: openAbove
                    ? Alignment.bottomLeft
                    : Alignment.topLeft,
                offset: Offset(0, openAbove ? -6 : 6),
                child: Material(
                  color: Colors.white,
                  elevation: 5,
                  shadowColor: Colors.black.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                  clipBehavior: Clip.antiAlias,
                  child: Container(
                    constraints: BoxConstraints(
                      maxHeight: popupHeight,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: StatefulBuilder(
                      builder: (context, setPopupState) {
                        final items = _filteredItems;

                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.searchText != null)
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: TextField(
                                  controller: _searchController,
                                  focusNode: _searchFocus,
                                  autofocus: true,
                                  onChanged: (_) {
                                    _highlightedIndex = -1;
                                    setPopupState(() {});
                                  },
                                  onSubmitted: (_) {
                                    final filtered = _filteredItems;

                                    if (filtered.length == 1) {
                                      _selectItem(filtered.first.value);
                                    }
                                  },
                                  decoration: InputDecoration(
                                    hintText:
                                    'Search ${widget.label}...',
                                    hintStyle: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme
                                          .onSurfaceVariant,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      size: 19,
                                    ),
                                    isDense: true,
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(6),
                                      borderSide: BorderSide(
                                        color:
                                        theme.colorScheme.primary,
                                        width: 1.2,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                            Flexible(
                              child: items.isEmpty
                                  ? Center(
                                child: Padding(
                                  padding:
                                  const EdgeInsets.all(20),
                                  child: Text(
                                    'No ${widget.label} found',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: theme.colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              )
                                  : ListView.builder(
                                shrinkWrap: true,
                                padding: const EdgeInsets.all(6),
                                itemCount: items.length,
                                itemBuilder: (context, index) {
                                  final item = items[index];
                                  final selected =
                                      item.value == widget.value;
                                  final highlighted =
                                      index == _highlightedIndex;

                                  return Padding(
                                    padding:
                                    const EdgeInsets.only(
                                      bottom: 2,
                                    ),
                                    child: InkWell(
                                      borderRadius:
                                      BorderRadius.circular(6),
                                      onTap: () =>
                                          _selectItem(item.value),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 120,
                                        ),
                                        padding:
                                        const EdgeInsets
                                            .symmetric(
                                          horizontal: 12,
                                          vertical: 11,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selected ||
                                              highlighted
                                              ? theme.colorScheme
                                              .primary
                                              .withValues(
                                            alpha: 0.08,
                                          )
                                              : Colors.transparent,
                                          borderRadius:
                                          BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: DefaultTextStyle(
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: theme
                                                      .colorScheme
                                                      .onSurface,
                                                  fontWeight: selected
                                                      ? FontWeight.w600
                                                      : FontWeight.w400,
                                                ),
                                                child: item.child,
                                              ),
                                            ),
                                            if (selected)
                                              Icon(
                                                Icons.check_rounded,
                                                size: 18,
                                                color: theme
                                                    .colorScheme
                                                    .primary,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selected = _selectedItem;

    return Focus(
      focusNode: _fieldFocus,
      onKeyEvent: _handleKeyEvent,
      child: CompositedTransformTarget(
        link: _layerLink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.label.isNotEmpty) ...[
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 7),
            ],

            MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: InkWell(
                onTap: _toggleDropdown,
                borderRadius: BorderRadius.circular(6),
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                splashColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 13),
                  decoration: BoxDecoration(
                    color: !widget.enabled
                        ? theme.colorScheme.surfaceContainerHighest
                        : _isHovered
                            ? theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.35)
                            : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _isOpen || _isHovered
                          ? theme.colorScheme.primary
                          : Colors.grey.shade300,
                      width: _isOpen || _isHovered ? 1.2 : 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      if (widget.icon != null) ...[
                        Icon(
                          widget.icon,
                          size: 19,
                          color: _isOpen || _isHovered
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 10),
                      ],

                      Expanded(
                        child: selected == null
                            ? Text(
                                widget.hint ?? 'Select ${widget.label}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              )
                            : DefaultTextStyle(
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface,
                                ),
                                child: selected.child,
                              ),
                      ),

                      AnimatedRotation(
                        turns: _isOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: _isOpen || _isHovered
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
