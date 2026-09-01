import ContactForm from "./ContactForm";

export const dynamic = "force-dynamic";

export default function ContactPage() {
  return (
    <div className="flex flex-col gap-4">
      <div>
        <h1 className="text-xl font-bold text-brand-gold">문의하기</h1>
        <p className="mt-1 text-xs text-white/50">
          결제, 지급, 오류 등 궁금한 점이나 문제를 남겨주세요. 확인하는 대로
          답변드려요.
        </p>
      </div>
      <ContactForm />
    </div>
  );
}
