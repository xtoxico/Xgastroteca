class QueueJob {
  final int id;
  final String url;
  final String status;
  final int retryCount;
  final String nextRetryAt;
  final String errorMsg;
  final String createdAt;

  QueueJob({
    required this.id,
    required this.url,
    required this.status,
    required this.retryCount,
    required this.nextRetryAt,
    required this.errorMsg,
    required this.createdAt,
  });

  factory QueueJob.fromJson(Map<String, dynamic> json) {
    return QueueJob(
      id: json['ID'],
      url: json['url'],
      status: json['status'],
      retryCount: json['retry_count'],
      nextRetryAt: json['next_retry_at'],
      errorMsg: json['error_msg'],
      createdAt: json['CreatedAt'],
    );
  }
}
