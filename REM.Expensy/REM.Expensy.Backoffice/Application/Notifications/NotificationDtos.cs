namespace REM.Expensy.Backoffice.Application.Notifications;

/// <summary>
/// Read model returned from notification queries.
/// </summary>
public record NotificationDto(
    Guid Id,
    string Title,
    string Body,
    string TypeName,
    Guid? RelatedId,
    bool IsRead,
    DateTime Created);

/// <summary>
/// Paginated read model returned from GET /api/notifications.
/// Always includes unreadCount regardless of the current page — this drives the
/// notification bell badge in the UI without a separate API call.
/// </summary>
public record NotificationPagedResult(
    int UnreadCount,          // total unread across ALL pages (not just this page)
    IReadOnlyList<NotificationDto> Items,
    int TotalCount,           // total notifications across all pages
    int Page,
    int PageSize);