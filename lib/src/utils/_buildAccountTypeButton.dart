import 'package:flutter/material.dart';

Widget _buildAccountTypeButton(String title, IconData icon) {
    var _selectedAccountType;
    final isSelected = _selectedAccountType == title;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedAccountType = title;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? const Color(0xFF135D39) : Colors.white70,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF135D39) : Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void setState(Null Function() param0) {
  }
  
