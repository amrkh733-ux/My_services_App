import firebase_admin
from firebase_admin import firestore
from firebase_functions import https_fn, options
import pandas as pd

# تهيئة التطبيق
if not firebase_admin._apps:
    firebase_admin.initialize_app()

db = firestore.client()

# --- الجزء الأول: محرك التوصيات الذكي (Smart Scoring) ---
@https_fn.on_call(
    memory=options.MemoryOption.GB_1, 
    timeout_sec=60
)
def get_ai_recommendations(request: https_fn.CallableRequest):
    category_query = request.data.get("category")
    
    if not category_query:
        raise https_fn.HttpsError(
            code=https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            message="يرجى تحديد القسم المطلوب."
        )

    try:
        docs = db.collection("providers").where("category", "==", category_query).stream()
        providers_list = []
        for doc in docs:
            item = doc.to_dict()
            item['id'] = doc.id
            providers_list.append(item)

        if not providers_list:
            return {"success": True, "recommendations": [], "message": "لا يوجد مزودين في هذا القسم"}

        df = pd.DataFrame(providers_list)
        # تحويل البيانات لأرقام لضمان عمل المعادلة
        df['stars'] = pd.to_numeric(df['stars'], errors='coerce').fillna(0)
        df['reviews_count'] = pd.to_numeric(df['reviews_count'], errors='coerce').fillna(0)
        
        # معادلة الترتيب الذكي (Smart Score)
        df['smart_score'] = (df['stars'] * 0.8) + (df['reviews_count'] * 0.01)
        recommended_df = df.sort_values(by='smart_score', ascending=False)
        
        return {
            "success": True,
            "recommendations": recommended_df.to_dict(orient='records')
        }
    except Exception as e:
        raise https_fn.HttpsError(code=https_fn.FunctionsErrorCode.INTERNAL, message=str(e))


# --- الجزء الثاني: نظام الرد الآلي (Chatbot) المطور ---
@https_fn.on_call()
def khadamatii_chatbot(request: https_fn.CallableRequest):
    # تحويل سؤال المستخدم لنص صغير (lowercase) وحذف الفراغات الزائدة للبحث بشكل أفضل
    user_question = request.data.get("question", "").strip()
    
    faq_data = {
        "ما هي منصة خدماتي": "منصة خدماتي هي منصة إلكترونية تربط بين مزودي الخدمات والعملاء داخل اليمن (تعز) في بيئة رقمية آمنة تتيح عرض الخدمات وطلبها وتنفيذها وإدارة الدفع والتقييم.",
        "التسجيل مجاني": "نعم التسجيل مجاني ويمكن إنشاء حساب بسهولة عبر إدخال البيانات الأساسية وتفعيل الحساب.",
        "توثيق هوية": "قد يُطلب توثيق رقم الهاتف وبعض البيانات الأساسية لتعزيز الأمان والمصداقية في المنصة.",
        "البحث عن خدمة": "يمكنك استخدام شريط البحث أو تصفح التصنيفات ثم مقارنة التقييمات والأسعار لاختيار المزود الأنسب.",
        "مزود الخدمة موثوق": "يمكنك الاطلاع على التقييمات السابقة وعدد الطلبات المنجزة وتعليقات العملاء للتأكد من الموثوقية.",
        "طلب خدمة": "بعد اختيار المزود يمكنك إرسال طلب يوضح تفاصيل العمل والاتفاق على السعر ومدة التنفيذ ثم تأكيد الطلب.",
        "التفاوض": "نعم يمكن التفاوض عبر نظام المراسلة الداخلية قبل تأكيد الطلب.",
        "إلغاء الطلب": "يمكن إلغاء الطلب قبل بدء التنفيذ، أما بعد البدء فيخضع الإلغاء لسياسة المنصة لضمان حقوق الطرفين.",
        "الدفع": "يتم الدفع عبر الوسائل المعتمدة داخل المنصة (مثل الكريمي أو غيرها) لضمان حقوق الطرفين.",
        "استرجاع المبلغ": "يمكن استرجاع المبلغ في حال ثبوت عدم تنفيذ الخدمة أو وجود إخلال بالشروط وفق سياسة المنصة.",
        "تقييم": "بعد إتمام الطلب يمكنك إضافة تقييم وكتابة تعليق يعكس تجربتك.",
        "شكوى": "يمكنك تقديم شكوى رسمية في حال كانت الخدمة غير مرضية ليتم مراجعتها من قبل الإدارة.",
        "مزود خدمة": "يمكنك التسجيل كمزود خدمة وإضافة بياناتك المهنية وتحديد تخصصك ورفع نماذج من أعمالك.",
        "العمولة": "يتم خصم نسبة عمولة بسيطة مقدارها 5% من قيمة كل طلب ناجح مقابل إدارة وتشغيل المنصة.",
        "أرباحي": "يتم تحويل الأرباح إلى رصيدك بعد تأكيد إتمام الخدمة ويمكنك طلب السحب وفق السياسة المعتمدة.",
        "حماية البيانات": "تستخدم المنصة تقنيات تشفير لضمان حماية بيانات المستخدمين وعدم مشاركتها خارج النظام.",
        "حل النزاعات": "يتم مراجعة الطلب والمحادثات لاتخاذ قرار عادل وتتم المحاسبة وفقاً للشروط وقانون العمل اليمني.",
        "ذكاء اصطناعي": "نعم، تعمل المنصة بنظام توصيات ذكي (Smart Scoring) يقترح أفضل الخدمات بناءً على الجودة والتقييمات.",
        "الدعم الفني": "يمكن التواصل مع الدعم عبر صفحة (اتصل بنا) أو من خلال نظام المراسلة داخل المنصة."
    }

    # منطق البحث المرن (يتحقق إذا كانت الكلمة موجودة داخل سؤال المستخدم)
    found_answer = None
    for key, response in faq_data.items():
        if key.lower() in user_question.lower():
            found_answer = response
            break
    
    if found_answer:
        return {"success": True, "answer": found_answer}
    else:
        return {
            "success": False, 
            "answer": "عذراً، لم أفهم سؤالك جيداً. يمكنك السؤال عن: (التسجيل، العمولة، كيفية الدفع، أو ضمانات المنصة)."
        }