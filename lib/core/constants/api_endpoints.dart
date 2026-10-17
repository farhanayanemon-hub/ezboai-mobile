class ApiEndpoints {
  // Live EzboAI production backend URL
  static String baseUrl = 'https://ezboai.com';

  // Mobile Auth Bridge
  static const String mobileLogin = '/api/mobile/auth/login';
  static const String mobileRegister = '/api/mobile/auth/register';
  static const String mobileVerifyOtp = '/api/mobile/auth/verify-otp';
  static const String mobileResendOtp = '/api/mobile/auth/resend-otp';
  static const String mobileForgotPassword = '/api/mobile/auth/forgot-password';
  static const String mobileGoogleLogin = '/api/mobile/auth/google';
  static const String mobileMe = '/api/mobile/auth/me';

  // Chat & AI Stream
  static const String chatStream = '/api/chat-stream';
  static const String chats = '/api/chats';
  static const String branchChat = '/api/chats/branch';
  static const String models = '/api/models';
  static const String readAloud = '/api/read-aloud';
  static const String promptSuggestions = '/api/prompt-suggestions';

  // Studios
  static const String imageGeneration = '/api/image-generation';
  static const String videoGeneration = '/api/video-generation';
  static const String musicGeneration = '/api/music-generation';
  static const String soundEffectsGeneration = '/api/sound-effects-generation';
  static const String audioGeneration = '/api/audio-generation'; // TTS
  static const String audioTranscription = '/api/audio-transcription'; // STT
  static const String voiceChange = '/api/voice-change';

  // Projects & Library
  static const String projects = '/api/projects';
  static const String library = '/api/library';
  static const String images = '/api/images';
  static const String filesText = '/api/files/text';

  // Subscriptions & Credits
  static const String pricingPlans = '/api/pricing-plans';
  static const String creditPlans = '/api/credits/plans';
  static const String creditPurchase = '/api/credits/purchase';
  static const String stripeCheckout = '/api/stripe/create-checkout-session';
  static const String manualCheckout = '/api/checkout/manual';
}
