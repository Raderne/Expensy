namespace REM.Expensy.Backoffice.Application.Categories;

/// <summary>
/// CRUD service for categories. System categories are visible to all users but can only be modified by the system.
/// </summary>
public interface ICategoryService
{
    /// <summary>
    /// Returns all system categories plus categories owned by the specified user, ordered by IsSystem descending then Name ascending.
    /// </summary>
    Task<IReadOnlyList<CategoryDto>> GetAllAsync(string userId, CancellationToken ct = default);

    /// <summary>
    /// Returns a single category visible to the user (system or user-owned), or <see langword="null"/> if not found.
    /// </summary>
    Task<CategoryDto?> GetByIdAsync(Guid id, string userId, CancellationToken ct = default);

    /// <summary>
    /// Creates a new user-owned category.
    /// </summary>
    Task<CategoryDto> CreateAsync(CreateCategoryRequest request, string userId, CancellationToken ct = default);

    /// <summary>
    /// Updates a user-owned category.
    /// Returns <see langword="null"/> if not found.
    /// </summary>
    /// <exception cref="InvalidOperationException">Thrown when attempting to update a system category or a category owned by another user.</exception>
    Task<CategoryDto?> UpdateAsync(Guid id, UpdateCategoryRequest request, string userId, CancellationToken ct = default);

    /// <summary>
    /// Soft-deletes a user-owned category. Returns <see langword="false"/> if not found.
    /// </summary>
    /// <exception cref="InvalidOperationException">Thrown when attempting to delete a system category or a category owned by another user.</exception>
    Task<bool> DeleteAsync(Guid id, string userId, CancellationToken ct = default);
}
