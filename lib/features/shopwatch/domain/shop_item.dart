/*
 *    Copyright (c) 2026 Juhász Mátyás. All rights reserved.
 */

import 'dart:math';

const itemProperties = [
  'stinky',
  'discounted',
  'slightly used',
  'glow-in-the-dark',
  'organic',
  'gluten-free',
  'suspicious',
  'extra spicy',
  'lukewarm',
  'homemade',
  'vintage',
  'waterproof',
  'left-handed',
  'family-size',
  'travel-size',
  'mysterious',
  'overripe',
  'limited-edition',
  'sparkly',
  'extra crunchy',
  'squeaky',
  'haunted',
  'sugar-free',
  'artisanal',
  'inflatable',
  'freshly expired',
  'wobbly',
  'decaf',
  'emotional support',
  'bargain-bin',
  'self-assembly',
  'microwave-safe',
  'vegan',
  'garlic-flavoured',
  'unicorn-themed',
  'off-brand',
  'industrial-strength',
  'pre-loved',
  'reversible',
  'turbo',
  'slightly sentimental',
  'award-winning',
  'smells-like-grandma',
  'grumpy',
  'tiny',
  'enormous',
  'lightly haunted',
  'battery-powered',
  'oddly warm',
  'premium',
  'mildly radioactive',
];

const itemNames = [
  'cheese',
  'socks',
  'hair gel',
  'pizza',
  'pyjamas',
  'carrier bag',
  'toaster',
  'rubber duck',
  'garden gnome',
  'lángos',
  'cucumber',
  'toilet roll',
  'umbrella',
  'banana',
  'flip-flops',
  'scented candle',
  'watermelon',
  'spatula',
  'kazoo',
  'traffic cone',
  'pillow',
  'pineapple',
  'frying pan',
  'lawn flamingo',
  'hot water bottle',
  'tin of beans',
  'jar of pickles',
  'bath bomb',
  'birthday card',
  'doormat',
  'hairnet',
  'lunchbox',
  'teapot',
  'yo-yo',
  'balloon',
  'bucket',
  'fridge magnet',
  'salami',
  'croissant',
  'potato',
  'duvet',
  'slipper',
  'egg',
  'sponge',
  'alarm clock',
  'stopwatch',
  'paprika',
  'wooden spoon',
  'shopping trolley',
  'disco ball',
];

const minPieces = 1;
const maxPieces = 5;
final shopItemCombinationCount =
    itemProperties.length * itemNames.length * (maxPieces - minPieces + 1);

class ShopItem {
  const ShopItem(this.property, this.name, this.pieces);

  final String property;
  final String name;
  final int pieces;

  // String get receiptLabel => '${'$property $name'.toUpperCase()} ×$pieces';
  String get receiptLabel => '$property $name'.toUpperCase();


  @override
  bool operator ==(Object other) =>
      other is ShopItem &&
      other.property == property &&
      other.name == name &&
      other.pieces == pieces;

  @override
  int get hashCode => Object.hash(property, name, pieces);
}

ShopItem nextItem(List<ShopItem> current, Random random) {
  if (current.length >= shopItemCombinationCount) {
    throw StateError('All shop item combinations have been used');
  }
  ShopItem item;
  do {
    item = ShopItem(
      itemProperties[random.nextInt(itemProperties.length)],
      itemNames[random.nextInt(itemNames.length)],
      minPieces + random.nextInt(maxPieces - minPieces + 1),
    );
  } while (current.contains(item));
  return item;
}
