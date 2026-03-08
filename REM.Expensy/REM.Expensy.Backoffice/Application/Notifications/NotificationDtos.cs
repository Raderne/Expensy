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
