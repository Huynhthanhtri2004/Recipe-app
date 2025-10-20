import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
class QuantityIncrementDecrement extends StatelessWidget {
  final int currentNumber;
  final Function() onAdd;
  final Function() onRemov;

  const QuantityIncrementDecrement({
    super.key,
    required this.currentNumber,
    required this.onAdd,
    required this.onRemov,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(
          width: 2.5,
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[700]!
              : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: onRemov,
            icon: Icon(
              Iconsax.minus,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "$currentNumber",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            onPressed: onAdd,
            icon: Icon(
              Iconsax.add,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
        ],
      ),
    );
  }
}