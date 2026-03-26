import 'package:flutter/material.dart';

enum UserType { client, provider, customer }

class FAQChatPage extends StatefulWidget {
  final UserType userType;
  const FAQChatPage({super.key, required this.userType});

  @override
  State<FAQChatPage> createState() => _FAQChatPageState();
}

class _FAQChatPageState extends State<FAQChatPage> {
  final TextEditingController controller = TextEditingController();
  final List<Map<String, String>> messages = [];
  List<String> suggestions = [];

  // 🔹 قاعدة البيانات بالصياغة الأكاديمية الجديدة
  final Map<String, Map<String, String>> faq = {
    "client": {
      "ما هي منصة خدماتي؟":
          "منصة خدماتي هي منصة إلكترونية وسيطة تهدف إلى ربط العملاء بمقدمي الخدمات داخل الجمهورية اليمنية من خلال بيئة رقمية منظمة وآمنة، تتيح البحث والتواصل وطلب الخدمات بسهولة.",
      "هل التسجيل في المنصة مجاني؟":
          "نعم، يمكن للمستخدمين إنشاء حساب في المنصة بشكل مجاني من خلال إدخال البيانات الأساسية، ثم تفعيل الحساب للبدء في استخدام الخدمات المتاحة.",
      "هل يتطلب استخدام المنصة توثيق الهوية؟":
          "قد يُطلب من المستخدم توثيق بعض البيانات مثل رقم الهاتف، لتعزيز مستوى الأمان وزيادة موثوقية التعاملات داخل المنصة.",
      "كيف يمكنني البحث عن خدمة مناسبة؟":
          "توفر المنصة نظام بحث وتصنيفات للخدمات، حيث يمكن للمستخدم تصفح الفئات أو استخدام شريط البحث لمقارنة العروض والتقييمات.",
      "كيف يمكنني التأكد من موثوقية مقدم الخدمة؟":
          "تتيح المنصة نظام تقييم ومراجعات يوضح مستوى رضا العملاء السابقين، بالإضافة إلى عرض عدد الطلبات المنجزة وخبرات مقدم الخدمة.",
      "كيف يمكنني طلب خدمة؟":
          "بعد اختيار الخدمة المناسبة، يتم إرسال طلب يتضمن تفاصيل العمل، ومن ثم يتم الاتفاق على السعر ومدة التنفيذ قبل تأكيد الطلب.",
      "هل يمكن التفاوض على سعر الخدمة؟":
          "نعم، تتيح المنصة نظام مراسلة داخلية يسمح للطرفين بمناقشة تفاصيل الطلب والتفاوض على السعر قبل اعتماد الطلب نهائياً.",
      "هل يمكن إلغاء الطلب بعد إرساله؟":
          "يمكن إلغاء الطلب قبل بدء التنفيذ، أما بعد البدء فيخضع الإلغاء لسياسات المنصة المنظمة لعملية تقديم الخدمات.",
      "كيف تتم عملية الدفع؟":
          "يتم تنفيذ عملية الدفع من خلال الوسائل المعتمدة داخل المنصة لضمان تنظيم العملية وحفظ حقوق جميع الأطراف.",
      "هل يمكن استرجاع المبلغ في حال حدوث مشكلة؟":
          "في حال وجود خلل واضح في التنفيذ، يمكن للعميل تقديم شكوى ليتم مراجعة الحالة واتخاذ القرار وفق سياسة المنصة.",
      "كيف يمكنني تقييم الخدمة؟":
          "بعد انتهاء التنفيذ، يمكن للعميل إضافة تقييم وكتابة تعليق يوضح تجربته، مما يساعد المستخدمين الآخرين في اتخاذ قراراتهم.",
      "ماذا أفعل إذا كانت الخدمة غير مرضية؟":
          "يمكن تقديم شكوى عبر نظام الدعم داخل المنصة، حيث يتم مراجعة الطلب والمحادثات لضمان العدالة بين الأطراف."
    },
    "provider": {
      "كيف يمكنني التسجيل كمقدم خدمة؟":
          "يمكن لأي مستخدم التسجيل كمقدم خدمة من خلال إنشاء حساب وإضافة البيانات المهنية مثل التخصص والخبرة ونماذج الأعمال السابقة.",
      "هل توجد رسوم للاشتراك في المنصة؟":
          "لا تفرض المنصة رسوم اشتراك ثابتة، حيث يعتمد نظامها على عمولة يتم اقتطاعها عند إتمام الطلبات بنجاح.",
      "كم تبلغ نسبة العمولة؟":
          "يتم خصم عمولة بنسبة 5٪ من قيمة الطلب المكتمل، وذلك مقابل إدارة المنصة وتوفير الخدمات التقنية والتنظيمية.",
      "كيف يمكنني إضافة خدمة جديدة؟":
          "يمكن لمقدم الخدمة إضافة خدماته من خلال لوحة التحكم الخاصة به، بإدخال اسم الخدمة ووصفها وسعرها ومدة تنفيذها.",
      "هل يمكن تعديل الخدمة بعد نشرها؟":
          "نعم، يمكن تعديل تفاصيل الخدمة في أي وقت طالما لا يوجد طلب نشط قيد التنفيذ مرتبط بها.",
      "متى يمكنني استلام أرباحي؟":
          "تُضاف الأرباح إلى رصيد مقدم الخدمة بعد تأكيد إتمام الطلب بنجاح، ويمكن سحبها وفق آلية السحب المعتمدة.",
      "كيف يمكنني زيادة فرص ظهور خدمتي؟":
          "يمكن تحسين الظهور من خلال وصف واضح، صور احترافية، جودة التنفيذ، والحفاظ على تقييمات إيجابية."
    },
    "general": {
      "كيف تحمي المنصة بيانات المستخدمين؟":
          "تعتمد المنصة على تقنيات حماية البيانات وإدارة صلاحيات الوصول لضمان سرية المعلومات وعدم استخدامها خارج نطاق النظام.",
      "كيف يتم حل النزاعات بين المستخدمين؟":
          "في حال حدوث خلاف، يتم تقديم شكوى للإدارة لمراجعة الطلب والمراسلات واتخاذ القرار وفق سياسات المنصة والقوانين المنظمة.",
      "هل توجد شروط وأحكام لاستخدام المنصة؟":
          "نعم، يجب على المستخدمين الموافقة على الشروط والأحكام قبل استخدام المنصة لضمان تنظيم العلاقة بين جميع الأطراف.",
      "هل يمكن استخدام المنصة في جميع المحافظات؟":
          "المنصة متاحة في جميع محافظات اليمن، للخدمات الرقمية (عن بُعد) أو الميدانية حسب موقع مقدم الخدمة.",
      "هل توفر المنصة تقنيات الذكاء الاصطناعي؟":
          "نعم، تعمل المنصة على استخدام تقنيات الذكاء الاصطناعي لتحليل بيانات المستخدمين واقتراح الخدمات الأنسب وفق الاهتمامات والسجل السابق.",
      "كيف يمكن التواصل مع الدعم الفني؟":
          "يمكن التواصل مع فريق الدعم من خلال صفحة 'اتصل بنا' داخل التطبيق أو عبر نظام الدعم الفني المخصص."
    }
  };

  @override
  void initState() {
    super.initState();
    String welcome = (widget.userType == UserType.provider)
        ? "مرحباً بك في نظام دعم مزودي الخدمات. كيف يمكننا مساعدتك اليوم؟"
        : "مرحباً بك في نظام دعم العملاء. كيف يمكننا مساعدتك في اختيار خدماتك؟";
    messages.add({"type": "bot", "text": welcome});
  }

  // 🔹 جلب الأسئلة المتاحة بناءً على نوع المستخدم (فلترة صارمة)
  Map<String, String> _getAvailableFaq() {
    Map<String, String> combined = {};
    if (widget.userType == UserType.client ||
        widget.userType == UserType.customer) {
      combined.addAll(faq["client"]!);
    } else if (widget.userType == UserType.provider) {
      combined.addAll(faq["provider"]!);
    }
    combined.addAll(faq["general"]!);
    return combined;
  }

  void updateSuggestions(String text) {
    setState(() {
      final availableFaq = _getAvailableFaq();
      suggestions = availableFaq.keys
          .where((q) => q.contains(text) && text.isNotEmpty)
          .toList();
    });
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      messages.add({"type": "user", "text": text});
      final availableFaq = _getAvailableFaq();
      String? answer;
      for (var key in availableFaq.keys) {
        if (key.trim() == text.trim() || key.contains(text)) {
          answer = availableFaq[key];
          break;
        }
      }
      messages.add({
        "type": "bot",
        "text": answer ??
            "❗ عذراً، لم أفهم سؤالك. يرجى الاختيار من الأسئلة المقترحة للحصول على أدق إجابة."
      });
      controller.clear();
      suggestions.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isProvider = widget.userType == UserType.provider;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A2A43),
        title: Text(isProvider ? "مركز دعم المزودين" : "مركز دعم العملاء",
            style: const TextStyle(
                fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: messages.length,
              itemBuilder: (context, index) =>
                  _buildChatBubble(messages[index]),
            ),
          ),
          if (suggestions.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children:
                    suggestions.map((s) => _buildSuggestionChip(s)).toList(),
              ),
            ),
          // تم وضع الـ TextField هنا مباشرة لضمان عدم فقدان الـ Focus
          _buildInputSection(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, String> msg) {
    bool isUser = msg["type"] == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.all(12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF0A2A43) : Colors.grey[200],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(15),
            topRight: const Radius.circular(15),
            bottomLeft: Radius.circular(isUser ? 15 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 15),
          ),
        ),
        child: Text(msg["text"]!,
            style: TextStyle(
                color: isUser ? Colors.white : Colors.black87, fontSize: 14)),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 12)),
        onPressed: () {
          controller.text = text;
          sendMessage(text);
        },
        backgroundColor: Colors.blue[50],
      ),
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)]),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: updateSuggestions, // يحافظ على الكيبورد مفتوحاً
              decoration: InputDecoration(
                hintText: "اكتب استفسارك هنا...",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF0A2A43),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => sendMessage(controller.text),
            ),
          ),
        ],
      ),
    );
  }
}
