import 'package:expense_management/core/language/app_language.dart';
import 'package:flutter/material.dart';

import 'package:expense_management/core/theme/app_colors.dart';
import 'package:expense_management/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardAiDigestCard extends ConsumerWidget{
  const DashboardAiDigestCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final digestAsync = ref.watch(fetchAiDigestProvider);
    final colors = context.colors;

    return digestAsync.when(data: (digest) => _buildCard(context,ref,colors,digest), error: (error,__)=>Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.red.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      'Lỗi AI Digest: $error',
      style: TextStyle(color: Colors.red, fontSize: 12),
    ),
  ), loading: () => _buildSkeleton(colors));
  }

  Widget _buildSkeleton(colors){
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20)
      ),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: colors.primary.withOpacity(0.3),
          ),
        )
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    WidgetRef ref,
    AppColorsExtension colors,
    dynamic digest
  ){
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          colors.primary.withOpacity(0.12),
          colors.primary.withOpacity(0.04)
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.primary.withOpacity(0.15))
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.12),
                shape: BoxShape.circle
              ),
              child: Icon(
                Icons.auto_awesome_rounded,
                color: colors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 18,),
            Text('ai_digest'.tr(ref), style: TextStyle(color: colors.primary, fontWeight: FontWeight.bold,fontSize: 14),)
          ],),
          const SizedBox(height: 12,),
          Text(
            digest.summary,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 13.5,
              height: 1.5
            ),
          ),
          if(digest.insight != null && digest.insight!.isNotEmpty) ...[
            const SizedBox(height: 10,),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12)
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡',style: TextStyle(fontSize: 14),),
                  const SizedBox(width: 8,),
                  Expanded(child: Text(
                    digest.insight!,
                    style: TextStyle(color: colors.textSecondary,fontSize: 12.5, fontStyle: FontStyle.italic, height: 1.4),
                  ))
                ],
              ),
            )
          ],
          if(digest.suggestedQuestions != null && digest.suggestedQuestions!.isNotEmpty) ...[
            const SizedBox(height: 12,),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: digest.suggestedQuestions!.map<Widget>((question){
                return InkWell(
                  onTap: () {
                    context.push('/ai-assistant', extra: question);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.primary.withOpacity(0.15))
                    ),
                    child: Text(
                      question,style: TextStyle(
                        color: colors.primary,
                        fontSize: 11.5
                      ),
                    ),
                  ),
                );
              }).toList(),
            )
          ],
        ],
      ),
    );
  }
}