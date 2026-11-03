import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class IslamicWorkQuote {
  final String quote;
  final String source;
  final String topic;

  const IslamicWorkQuote({
    required this.quote,
    required this.source,
    required this.topic,
  });
}

const List<IslamicWorkQuote> islamicQuotes = [
  IslamicWorkQuote(
    quote:
        'Sesungguhnya Allah mencintai seorang hamba yang apabila bekerja, ia melakukannya dengan itqan (sungguh-sungguh, rapi, dan profesional).',
    source: 'HR. Al-Baihaqi & Ath-Thabrani',
    topic: 'Profesionalisme',
  ),
  IslamicWorkQuote(
    quote:
        'Dan katakanlah, "Bekerjalah kamu, maka Allah dan Rasul-Nya serta orang-orang mukmin akan melihat pekerjaanmu itu."',
    source: 'QS. At-Taubah: 105',
    topic: 'Etos Kerja',
  ),
  IslamicWorkQuote(
    quote:
        'Tidaklah seseorang memakan suatu makanan yang lebih baik daripada makanan dari hasil usaha dan keringatnya sendiri.',
    source: 'HR. Bukhari no. 2072',
    topic: 'Kemandirian',
  ),
  IslamicWorkQuote(
    quote:
        'Barangsiapa di sore hari merasa lelah karena bekerja mencari rezeki yang halal, maka pada saat itu diampuni dosa-dosanya.',
    source: 'HR. Ath-Thabrani',
    topic: 'Penggugur Dosa',
  ),
  IslamicWorkQuote(
    quote:
        'Mencari rezeki yang halal adalah kewajiban setelah kewajiban pokok beribadah.',
    source: 'HR. Al-Baihaqi & Ath-Thabrani',
    topic: 'Nafkah Halal',
  ),
  IslamicWorkQuote(
    quote:
        'Maka apabila engkau telah selesai (dari suatu urusan), tetaplah bekerja keras (untuk urusan yang lain), dan hanya kepada Tuhanmulah engkau berharap.',
    source: 'QS. Al-Insyirah: 7-8',
    topic: 'Pantang Menyerah',
  ),
  IslamicWorkQuote(
    quote:
        'Bersemangatlah terhadap hal-hal yang bermanfaat bagimu, mohonlah pertolongan kepada Allah, dan janganlah merasa lemah.',
    source: 'HR. Muslim no. 2664',
    topic: 'Optimisme',
  ),
  IslamicWorkQuote(
    quote:
        'Sesungguhnya Allah suka melihat hamba-Nya bersungguh-sungguh dalam mencari nafkah yang halal.',
    source: 'HR. Ad-Dailami',
    topic: 'Keberkahan',
  ),
];

class LoginMotivationCard extends StatelessWidget {
  final int quoteIndex;
  final VoidCallback onTap;

  const LoginMotivationCard({
    super.key,
    required this.quoteIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final quote = islamicQuotes[quoteIndex % islamicQuotes.length];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? context.borderColor : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: Column(
                key: ValueKey<int>(quoteIndex),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '“${quote.quote}”',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                      color: context.textSecondaryColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      quote.source,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.primary.withValues(alpha: 0.9)
                            : AppColors.primaryDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

