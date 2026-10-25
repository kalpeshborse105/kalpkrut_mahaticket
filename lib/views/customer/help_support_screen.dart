import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import 'policy_viewer_screen.dart';
import 'post_event_screen.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _messageController = TextEditingController();
  final _emailController = TextEditingController();

  final List<Map<String, dynamic>> _faqs = [
    {
      'q': 'How do I download my ticket after booking?',
      'q_mr': 'बुकिंगनंतर तिकीट कसे डाउनलोड करावे?',
      'a': 'Your digital M-Ticket with secure QR code is automatically saved in "My Tickets" and sent to your WhatsApp and email instantly after payment.',
      'policy': null,
    },
    {
      'q': 'Can I cancel or reschedule my booking?',
      'q_mr': 'तिकीट रद्द किंवा वेळ बदलता येईल का?',
      'a': 'Tickets once booked cannot be cancelled or rescheduled as per auditorium and theatre house policy, unless the organizer officially cancels the show.',
      'policy': 'refund',
    },
    {
      'q': "I didn't receive my ticket on WhatsApp. What to do?",
      'q_mr': 'व्हॉट्सअ‍ॅपवर तिकीट न आल्यास काय करावे?',
      'a': 'Open the "My Tickets" tab in MahaTicket to view and download your valid pass with HMAC QR code any time.',
      'policy': null,
    },
    {
      'q': 'How does QR scanning work at the venue entrance?',
      'q_mr': 'नाट्यगृह प्रवेशद्वारावर QR स्कॅनिंग कसे चालते?',
      'a': 'Simply display your mobile M-Ticket screen to the gate volunteer. Each QR code is cryptographically signed and valid for single entry.',
      'policy': null,
    },
    {
      'q': 'Is my payment information safe and secure?',
      'q_mr': 'पेमेंट पूर्णपणे सुरक्षित आहे का?',
      'a': 'Yes, 100% secure. Transactions are processed via Razorpay 256-bit encrypted gateway. We never store bank or card credentials.',
      'policy': 'privacy',
    },
    {
      'q': 'How can I list my drama play or event on MahaTicket?',
      'q_mr': 'महाटिकिटवर नाटक अथवा कार्यक्रम कसा नोंदवावा?',
      'a': 'Click "Partner With Us / आयोजक नोंदणी" from your profile or contact our producer team at partners@mahaticket.com.',
      'policy': 'post_event',
    },
  ];

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/919420000000?text=Hello%20MahaTicket%20Support');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmail() async {
    final uri = Uri.parse('mailto:support@mahaticket.com?subject=MahaTicket%20Help%20Request');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('मदत व ग्राहक सेवा (Help & Support)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text('Customer Care & Concierge', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contact Channels
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.surface, AppColors.surfaceLight],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.neonGreen.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.support_agent, color: AppColors.neonGreen, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '२४x७ महाटिकिट मदत केंद्र',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'सकाळी ९:०० ते रात्री १०:०० थेट सहाय्य',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 8),

                  // WhatsApp button
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.chat_outlined, color: Color(0xFF25D366)),
                    ),
                    title: const Text('WhatsApp Concierge Desk', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                    subtitle: const Text('+91 94200 00000 (Instant Chat)', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                    onTap: _openWhatsApp,
                  ),

                  // Email button
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.mail_outline, color: AppColors.primary),
                    ),
                    title: const Text('Email Help Desk', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                    subtitle: const Text('support@mahaticket.com', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
                    onTap: _openEmail,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const Text(
              'वारंवार विचारले जाणारे प्रश्न (FAQ)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
            ),
            const SizedBox(height: 12),

            // FAQ Accordions
            ..._faqs.map((faq) {
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.white10),
                ),
                child: ExpansionTile(
                  collapsedIconColor: AppColors.textSecondary,
                  iconColor: AppColors.primary,
                  title: Text(
                    faq['q_mr'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                  ),
                  subtitle: Text(
                    faq['q'],
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            faq['a'],
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                          ),
                          if (faq['policy'] != null) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () {
                                if (faq['policy'] == 'post_event') {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PostEventScreen()));
                                } else {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => PolicyViewerScreen(initialPolicy: faq['policy']),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                faq['policy'] == 'post_event' ? 'इव्हेंट नोंदणी करा (Open Form) →' : 'धोरण वाचा (View Policy) →',
                                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),
            // Quick Message form
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('संदेश पाठवा (Send Us a Message)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                  const SizedBox(height: 6),
                  const Text('काही विशेष अडचण असल्यास आम्हास थेट कळवा:', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'आपला ईमेल किंवा फोन नंबर'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _messageController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'आपला संदेश / प्रश्न'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        if (_messageController.text.trim().isEmpty) return;
                        _emailController.clear();
                        _messageController.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('आपला संदेश प्राप्त झाला आहे. आम्ही लवकरच संपर्क करू!')),
                        );
                      },
                      child: const Text('संदेश पाठवा (Send Message)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }
}
