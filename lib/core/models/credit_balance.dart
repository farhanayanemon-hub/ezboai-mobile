class CreditBalance {
  final int text;
  final int image;
  final int video;
  final int audio;

  const CreditBalance({
    this.text = 0,
    this.image = 0,
    this.video = 0,
    this.audio = 0,
  });

  factory CreditBalance.fromJson(Map<String, dynamic> json) {
    return CreditBalance(
      text: (json['text'] as num?)?.toInt() ?? 0,
      image: (json['image'] as num?)?.toInt() ?? 0,
      video: (json['video'] as num?)?.toInt() ?? 0,
      audio: (json['audio'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'image': image,
      'video': video,
      'audio': audio,
    };
  }

  int get total => text + image + video + audio;
}
