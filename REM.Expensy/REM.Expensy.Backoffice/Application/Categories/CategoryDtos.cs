namespace REM.Expensy.Backoffice.Application.Categories;

/// <summary>
/// Read model returned from category queries.
/// </summary>
public record CategoryDto(Guid Id, string Name, string Icon, string Color, bool IsSystem);

/// <summary>
/// Payload for creating a new user-owned category.
/// </summary>
public record CreateCategoryRequest(string Name, string Icon, string Color);

/// <summary>
/// Payload for updating an existing user-owned category.
/// </summary>
public record UpdateCategoryRequest(string Name, string Icon, string Color);
