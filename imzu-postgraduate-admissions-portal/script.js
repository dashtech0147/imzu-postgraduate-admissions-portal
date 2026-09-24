const SUPABASE_URL = 'YOUR_SUPABASE_URL';
const SUPABASE_PUBLISHABLE_KEY = 'YOUR_SUPABASE_PUBLISHABLE_KEY';
const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);

const showResult = (target, message, isError = false) => {
  target.textContent = message;
  target.classList.add('show');
  target.style.background = isError ? '#fff0ed' : '#e5f3e9';
  target.style.color = isError ? '#9a321c' : '#125f3c';
  target.style.borderLeftColor = isError ? '#cc4d2e' : '#168554';
};

document.querySelector('.menu-toggle').addEventListener('click', (event) => {
  const nav = document.querySelector('.nav nav');
  const isOpen = nav.classList.toggle('open');
  event.currentTarget.setAttribute('aria-expanded', isOpen);
});

document.getElementById('verifyForm').addEventListener('submit', (event) => {
  event.preventDefault();
  loadAdmissionDecision();
});

async function loadAdmissionDecision() {
  const result = document.getElementById('verifyResult');
  const matriculationNumber = document.getElementById('matriculationNumber').value.trim();
  const programme = document.getElementById('programme').value;
  const { data, error } = await supabaseClient.rpc('check_admission_status', {
    p_matriculation_number: matriculationNumber,
    p_programme: programme,
  });
  if (error) {
    showResult(result, 'We could not verify this matriculation number right now. Please try again later.', true);
    return;
  }
  const admission = data?.[0];
  if (!admission) {
    showResult(result, 'No admission record matches that matriculation number and programme.', true);
    return;
  }
  const course = admission.professional_course ? ` Professional course: ${admission.professional_course}.` : '';
  const messages = {
    pending: `${admission.full_name}, your application for ${admission.programme_name} has been received.${course} An admission decision has not yet been published.`,
    admitted: `Congratulations, ${admission.full_name}. You have been offered provisional admission to ${admission.programme_name} for the ${admission.session} academic session.${course}`,
    not_admitted: `${admission.full_name}, a decision has been recorded for your ${admission.session} application.${course} Please contact the School of Postgraduate Studies if you need assistance.`,
  };
  showResult(result, messages[admission.status] || 'Your admission status is being updated.');
}

document.getElementById('loginForm').addEventListener('submit', async (event) => {
  event.preventDefault();
  const result = document.getElementById('loginResult');
  const button = document.getElementById('loginButton');
  button.disabled = true;
  button.textContent = 'Signing in...';
  const { error } = await supabaseClient.auth.signInWithPassword({
    email: document.getElementById('email').value.trim(),
    password: document.getElementById('password').value,
  });
  button.disabled = false;
  button.innerHTML = 'Sign in <span>→</span>';
  if (error) {
    showResult(result, 'We could not sign you in. Check your email and password, then try again.', true);
    return;
  }
  showResult(result, 'Signed in securely. Your admission decision has been loaded below.');
  await loadAdmissionDecision();
  document.getElementById('verify').scrollIntoView({ behavior: 'smooth', block: 'center' });
});
