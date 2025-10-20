import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:recipe_app/Utils/constants.dart';
import 'package:recipe_app/Widget/video_player_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';

class CookingGuideScreen extends StatefulWidget {
  final DocumentSnapshot<Object?> documentSnapshot;

  const CookingGuideScreen({super.key, required this.documentSnapshot});

  @override
  State<CookingGuideScreen> createState() => _CookingGuideScreenState();
}

class _CookingGuideScreenState extends State<CookingGuideScreen> {
  int _currentStep = 0;
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isTimerRunning = false;
  bool _isCookingStarted = false;
  bool _isCompleted = false;
  bool _showIngredients = true;

  List<Map<String, dynamic>> _cookingSteps = [];
  List<Map<String, dynamic>> _ingredients = [];
  String? _videoUrl;
  int _totalTime = 0;
  String _recipeId = '';
  String _recipeName = '';

  // Sound and vibration
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _prepareCookingData();
    _loadCookingProgress();
    _loadSettings();
  }

  void _prepareCookingData() {
    final data = widget.documentSnapshot.data() as Map<String, dynamic>?;
    
    _recipeId = widget.documentSnapshot.id;
    _recipeName = data?['name'] ?? 'Món ăn';
    
    // Lấy video URL
    _videoUrl = data?['videoUrl'] as String?;
    
    // Lấy thời gian nấu (phút)
    _totalTime = (data?['time'] as int?) ?? 0;
    
    // Lấy hướng dẫn nấu ăn
    final instructions = (data?['instructions'] as List<dynamic>?) ?? [];
    _cookingSteps = instructions.asMap().entries.map((entry) {
      return {
        'step': entry.key + 1,
        'instruction': entry.value.toString(),
        'completed': false,
      };
    }).toList();

    // Lấy nguyên liệu
    _prepareIngredients(data);
  }

  void _prepareIngredients(Map<String, dynamic>? data) {
    try {
      // Thử schema mới trước
      final ingredientsObj = (data?['ingredients'] as List<dynamic>?) ?? [];
      if (ingredientsObj.isNotEmpty) {
        _ingredients = ingredientsObj.map<Map<String, dynamic>>((item) {
          final ingredient = item as Map<String, dynamic>;
          return {
            'name': ingredient['name']?.toString() ?? '',
            'amount': ingredient['amount']?.toString() ?? '0',
            'unit': ingredient['unit']?.toString() ?? 'g',
            'imageUrl': ingredient['imageUrl']?.toString() ?? '',
            'prepared': false,
          };
        }).toList();
        return;
      }
    } catch (e) {
      // Fallback to old schema
    }

    // Schema cũ
    final names = (data?['ingredientsName'] as List<dynamic>?) ?? [];
    final amounts = (data?['ingredientsAmount'] as List<dynamic>?) ?? [];
    final images = (data?['ingredientsImage'] as List<dynamic>?) ?? [];

    _ingredients = List.generate(names.length, (index) {
      return {
        'name': names[index]?.toString() ?? '',
        'amount': index < amounts.length ? amounts[index]?.toString() ?? '0' : '0',
        'unit': 'g',
        'imageUrl': index < images.length ? images[index]?.toString() ?? '' : '',
        'prepared': false,
      };
    });
  }

  Future<void> _loadCookingProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressKey = 'cooking_progress_$_recipeId';
      final progressData = prefs.getString(progressKey);
      
      if (progressData != null) {
        final progress = jsonDecode(progressData) as Map<String, dynamic>;
        setState(() {
          _currentStep = progress['currentStep'] ?? 0;
          _elapsedSeconds = progress['elapsedSeconds'] ?? 0;
          _isCookingStarted = progress['isCookingStarted'] ?? false;
          
          final steps = progress['steps'] as List<dynamic>?;
          if (steps != null) {
            for (int i = 0; i < _cookingSteps.length && i < steps.length; i++) {
              _cookingSteps[i]['completed'] = steps[i]['completed'] ?? false;
            }
          }
          
          final ingredients = progress['ingredients'] as List<dynamic>?;
          if (ingredients != null) {
            for (int i = 0; i < _ingredients.length && i < ingredients.length; i++) {
              _ingredients[i]['prepared'] = ingredients[i]['prepared'] ?? false;
            }
          }
        });
      }
    } catch (e) {
      print('Error loading cooking progress: $e');
    }
  }

  Future<void> _saveCookingProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final progressKey = 'cooking_progress_$_recipeId';
      
      final progress = {
        'currentStep': _currentStep,
        'elapsedSeconds': _elapsedSeconds,
        'isCookingStarted': _isCookingStarted,
        'steps': _cookingSteps.map((step) => {
          'completed': step['completed'],
        }).toList(),
        'ingredients': _ingredients.map((ingredient) => {
          'prepared': ingredient['prepared'],
        }).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await prefs.setString(progressKey, jsonEncode(progress));
    } catch (e) {
      print('Error saving cooking progress: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _soundEnabled = prefs.getBool('cooking_sound_enabled') ?? true;
        _vibrationEnabled = prefs.getBool('cooking_vibration_enabled') ?? true;
      });
    } catch (e) {
      print('Error loading settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('cooking_sound_enabled', _soundEnabled);
      await prefs.setBool('cooking_vibration_enabled', _vibrationEnabled);
    } catch (e) {
      print('Error saving settings: $e');
    }
  }

  void _startCooking() {
    setState(() {
      _isCookingStarted = true;
      _isTimerRunning = true;
    });
    _startTimer();
    _saveCookingProgress();
    _playNotificationSound();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
        _saveCookingProgress();
        
        // Kiểm tra thời gian hoàn thành
        if (_elapsedSeconds >= _totalTime * 60 && _totalTime > 0) {
          _onCookingComplete();
        }
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isTimerRunning = false;
    });
    _timer?.cancel();
    _saveCookingProgress();
  }

  void _resumeTimer() {
    setState(() {
      _isTimerRunning = true;
    });
    _startTimer();
    _saveCookingProgress();
  }

  void _resetTimer() {
    setState(() {
      _elapsedSeconds = 0;
      _isTimerRunning = false;
      _isCookingStarted = false;
      _isCompleted = false;
    });
    _timer?.cancel();
    _saveCookingProgress();
  }

  void _onCookingComplete() {
    setState(() {
      _isCompleted = true;
      _isTimerRunning = false;
    });
    _timer?.cancel();
    _playCompletionSound();
    _showCompletionDialog();
  }

  void _playNotificationSound() {
    if (_soundEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _playCompletionSound() {
    if (_soundEnabled) {
      HapticFeedback.heavyImpact();
    }
    if (_vibrationEnabled) {
      HapticFeedback.vibrate();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Iconsax.tick_circle, color: Colors.green, size: 32),
            const SizedBox(width: 12),
            const Text('Hoàn thành!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Chúc mừng! Bạn đã hoàn thành món $_recipeName'),
            const SizedBox(height: 16),
            Text(
              'Thời gian nấu: ${_formatTime(_elapsedSeconds)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetTimer();
            },
            child: const Text('Nấu lại'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _shareCookingResult();
            },
            child: const Text('Chia sẻ'),
          ),
        ],
      ),
    );
  }

  void _shareCookingResult() {
    // TODO: Implement sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Tính năng chia sẻ sẽ được thêm sau!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < _cookingSteps.length - 1) {
      setState(() {
        _cookingSteps[_currentStep]['completed'] = true;
        _currentStep++;
      });
      _saveCookingProgress();
      _playNotificationSound();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
        _cookingSteps[_currentStep]['completed'] = false;
      });
      _saveCookingProgress();
    }
  }

  void _completeStep() {
    setState(() {
      _cookingSteps[_currentStep]['completed'] = true;
    });
    _saveCookingProgress();
    _playNotificationSound();
    
    // Tự động chuyển bước tiếp theo nếu có
    if (_currentStep < _cookingSteps.length - 1) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _nextStep();
        }
      });
    }
  }

  void _toggleIngredient(int index) {
    setState(() {
      _ingredients[index]['prepared'] = !(_ingredients[index]['prepared'] as bool);
    });
    _saveCookingProgress();
    _playNotificationSound();
  }

  void _toggleIngredientsView() {
    setState(() {
      _showIngredients = !_showIngredients;
    });
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cài đặt'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              title: const Text('Âm thanh thông báo'),
              subtitle: const Text('Phát âm thanh khi hoàn thành bước'),
              value: _soundEnabled,
              onChanged: (value) {
                setState(() {
                  _soundEnabled = value;
                });
                _saveSettings();
              },
            ),
            SwitchListTile(
              title: const Text('Rung'),
              subtitle: const Text('Rung điện thoại khi hoàn thành'),
              value: _vibrationEnabled,
              onChanged: (value) {
                setState(() {
                  _vibrationEnabled = value;
                });
                _saveSettings();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _recipeName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: kprimaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Iconsax.setting_2),
            onPressed: _showSettingsDialog,
            tooltip: 'Cài đặt',
          ),
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: _resetTimer,
            tooltip: 'Reset timer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Timer Section
            _buildTimerSection(),
            
            // Ingredients Checklist
            if (_ingredients.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildIngredientsSection(),
            ],
            
            // Video Section (if available)
            if (_videoUrl != null && _videoUrl!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildVideoSection(),
            ],
            
            // Cooking Steps
            const SizedBox(height: 16),
            _buildCookingSteps(),
            
            // Navigation Buttons
            const SizedBox(height: 20),
            _buildNavigationButtons(),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kprimaryColor, kprimaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kprimaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thời gian nấu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${_totalTime} phút',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_isCookingStarted) ...[
                Column(
                  children: [
                    Text(
                      _formatTime(_elapsedSeconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Đã trôi qua',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (!_isCookingStarted)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startCooking,
                icon: const Icon(Iconsax.play),
                label: const Text('Bắt đầu nấu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kprimaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isTimerRunning ? _pauseTimer : _resumeTimer,
                    icon: Icon(_isTimerRunning ? Iconsax.pause : Iconsax.play),
                    label: Text(_isTimerRunning ? 'Tạm dừng' : 'Tiếp tục'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kprimaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _resetTimer,
                    icon: const Icon(Iconsax.refresh),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection() {
    final preparedCount = _ingredients.where((ingredient) => ingredient['prepared'] as bool).length;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Iconsax.shopping_cart, color: kprimaryColor),
            title: const Text(
              'Nguyên liệu cần chuẩn bị',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('$preparedCount/${_ingredients.length} đã chuẩn bị'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(_showIngredients ? Iconsax.arrow_up_2 : Iconsax.arrow_down_2),
                  onPressed: _toggleIngredientsView,
                ),
              ],
            ),
          ),
          if (_showIngredients) ...[
            const Divider(height: 1),
            ...List.generate(_ingredients.length, (index) {
              final ingredient = _ingredients[index];
              final isPrepared = ingredient['prepared'] as bool;
              
              return ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: isPrepared ? Colors.green : Colors.grey.shade300,
                  child: ingredient['imageUrl'] != null && ingredient['imageUrl'].toString().isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.network(
                            ingredient['imageUrl'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              isPrepared ? Iconsax.tick_circle : Iconsax.shopping_cart,
                              color: isPrepared ? Colors.white : Colors.grey,
                            ),
                          ),
                        )
                      : Icon(
                          isPrepared ? Iconsax.tick_circle : Iconsax.shopping_cart,
                          color: isPrepared ? Colors.white : Colors.grey,
                        ),
                ),
                title: Text(
                  ingredient['name'],
                  style: TextStyle(
                    decoration: isPrepared ? TextDecoration.lineThrough : null,
                    color: isPrepared ? Colors.grey : null,
                  ),
                ),
                subtitle: Text('${ingredient['amount']} ${ingredient['unit']}'),
                trailing: Checkbox(
                  value: isPrepared,
                  onChanged: (value) => _toggleIngredient(index),
                  activeColor: Colors.green,
                ),
                onTap: () => _toggleIngredient(index),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildVideoSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
          child: VideoPlayerWidget(
          videoUrl: _videoUrl!,
          autoPlay: false,
          showControls: true,
          aspectRatio: 16 / 9,
        ),
      ),
    );
  }

  Widget _buildCookingSteps() {
    final completedSteps = _cookingSteps.where((step) => step['completed'] as bool).length;
    final progress = _cookingSteps.isNotEmpty ? completedSteps / _cookingSteps.length : 0.0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Hướng dẫn nấu ăn',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '$completedSteps/${_cookingSteps.length} bước',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progress == 1.0 ? Colors.green : kprimaryColor,
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(_cookingSteps.length, (index) {
            final step = _cookingSteps[index];
            final isCurrentStep = index == _currentStep;
            final isCompleted = step['completed'] as bool;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isCurrentStep 
                    ? kprimaryColor.withOpacity(0.1)
                    : isCompleted 
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrentStep 
                      ? kprimaryColor
                      : isCompleted 
                          ? Colors.green
                          : Colors.grey.withOpacity(0.3),
                  width: isCurrentStep ? 2 : 1,
                ),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isCompleted 
                      ? Colors.green
                      : isCurrentStep 
                          ? kprimaryColor
                          : Colors.grey,
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white)
                      : Text(
                          '${step['step']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                title: Text(
                  step['instruction'],
                  style: TextStyle(
                    fontWeight: isCurrentStep ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? Colors.green.shade700 : null,
                  ),
                ),
                trailing: isCurrentStep && !isCompleted
                    ? IconButton(
                        onPressed: _completeStep,
                        icon: const Icon(Icons.check_circle_outline),
                        color: Colors.green,
                      )
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    final allStepsCompleted = _cookingSteps.every((step) => step['completed'] as bool);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentStep > 0 ? _previousStep : null,
                  icon: const Icon(Iconsax.arrow_left),
                  label: const Text('Bước trước'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _currentStep < _cookingSteps.length - 1 ? _nextStep : null,
                  icon: const Icon(Iconsax.arrow_right),
                  label: const Text('Bước tiếp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kprimaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!allStepsCompleted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _completeStep,
                icon: const Icon(Iconsax.tick_circle),
                label: const Text('Hoàn thành bước này'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Iconsax.tick_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Tất cả các bước đã hoàn thành!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
