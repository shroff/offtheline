import 'package:flutter/material.dart';
import 'formats.dart';

const _cardMarginHorizontal = 4.0;
const _cardMarginVertical = 4.0;
const _cardRadius = 6.0;

class GroupedCardList extends StatelessWidget {
  final String titleText;
  final String? subtitleText;
  final String? trailingText;
  final Widget? trailing;
  final List<GroupedCardItemData> items;
  final Function(bool)? setCollapsed;
  final bool collapsed;

  const GroupedCardList({
    Key? key,
    required this.titleText,
    this.subtitleText,
    this.trailingText,
    this.trailing,
    required this.items,
    this.setCollapsed,
    this.collapsed = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => SliverList(
        delegate: items == null
            ? SliverChildListDelegate.fixed([
                GroupedCardHeader(
                  title: titleText,
                  subtitle: subtitleText,
                  collapsed: true,
                  showExpansionIcon: false,
                ),
                CardFragmentMiddle(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                GroupedCardFooter(),
              ])
            : SliverChildBuilderDelegate(
                (context, index) => (index == 0)
                    ? GroupedCardHeader(
                        title: titleText,
                        subtitle: subtitleText,
                        trailing: trailing != null
                            ? trailing
                            : trailingText != null
                                ? Text(
                                    trailingText!,
                                    style: const TextStyle(fontSize: 18),
                                  )
                                : null,
                        collapsed: collapsed || items.isEmpty,
                        onTap: (setCollapsed == null)
                            ? null
                            : () {
                                setCollapsed!(!collapsed);
                              },
                        showExpansionIcon: (setCollapsed != null),
                      )
                    : (index > items.length)
                        ? GroupedCardFooter()
                        : GroupedCardItem(data: items[index - 1]),
                childCount: 1 +
                    ((collapsed || items.isEmpty) ? 0 : (items.length + 1))),
      );
}

class GroupedCardHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final bool collapsed;
  final bool showExpansionIcon;
  final void Function()? onTap;

  const GroupedCardHeader({
    Key? key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.collapsed = false,
    this.onTap,
    this.showExpansionIcon = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => collapsed
      ? Card(
          child: buildContents(context),
        )
      : CardFragmentTop(
          child: buildContents(context),
        );

  Widget buildContents(context) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: <Widget >[
              if (showExpansionIcon)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Icon(
                      collapsed ? Icons.arrow_drop_down : Icons.arrow_drop_up),
                ),
              Expanded(
                flex: 1,
                child: Text(
                  title,
                  style: TextStyle(fontSize: 20),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      );
}

class GroupedCardItemData {
  final int sortOrder;
  final int? secondarySortOrder;
  final String title;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final int? amount;
  final String? subtitle;
  final String? third;

  GroupedCardItemData({
    required this.sortOrder,
    this.secondarySortOrder,
    required this.title,
    this.amount,
    this.subtitle,
    this.third,
    this.onTap,
    this.onLongPress,
  });
}

class GroupedCardItem extends StatelessWidget {
  final GroupedCardItemData data;

  const GroupedCardItem({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) => CardFragmentMiddle(
        child: InkWell(
          onTap: data.onTap,
          onLongPress: data.onLongPress,
          child: buildContents(),
        ),
      );

  Widget buildContents() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Column(
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        data.title,
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      ),
                      if (data.subtitle?.isNotEmpty ?? false)
                        Text(data.subtitle!),
                      if (data.third?.isNotEmpty ?? false)
                        Text(
                          data.third!,
                          style: const TextStyle(color: Colors.blueGrey),
                        ),
                    ],
                  ),
                ),
                if (data.amount != null)
                  Text(
                    (data.amount == 0)
                        ? '-'
                        : currencyFormat.format(data.amount),
                    style: const TextStyle(fontSize: 16),
                  ),
              ],
            ),
          ],
        ),
      );
}

class GroupedCardFooter extends StatelessWidget {
  const GroupedCardFooter({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => CardFragmentBottom(
          child: SizedBox.fromSize(
        child: Container(),
        size: const Size(double.infinity, 8.0 + _cardRadius),
      ));
}

class CardFragmentTop extends StatelessWidget {
  final Widget child;
  final double? marginHorizontal;
  final double? marginTop;

  const CardFragmentTop(
      {Key? key, required this.child, this.marginTop, this.marginHorizontal})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.only(
          top: marginTop ?? _cardMarginVertical,
          left: marginHorizontal ?? _cardMarginHorizontal,
          right: marginHorizontal ?? _cardMarginHorizontal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(_cardRadius)),
        ),
        child: child,
      );
}

class CardFragmentMiddle extends StatelessWidget {
  final Widget child;
  final double? marginHorizontal;

  const CardFragmentMiddle(
      {Key? key, required this.child, this.marginHorizontal})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.symmetric(
          horizontal: marginHorizontal ?? _cardMarginHorizontal,
        ),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only()),
        child: child,
      );
}

class CardFragmentBottom extends StatelessWidget {
  final Widget child;
  final double? marginHorizontal;
  final double? marginBottom;

  const CardFragmentBottom(
      {Key? key, required this.child, this.marginBottom, this.marginHorizontal})
      : super(key: key);

  @override
  Widget build(BuildContext context) => Card(
        margin: EdgeInsets.only(
          bottom: marginBottom ?? _cardMarginVertical,
          left: marginHorizontal ?? _cardMarginHorizontal,
          right: marginHorizontal ?? _cardMarginHorizontal,
        ),
        shape: RoundedRectangleBorder(
          borderRadius:
              const BorderRadius.vertical(bottom: Radius.circular(_cardRadius)),
        ),
        child: child,
      );
}
