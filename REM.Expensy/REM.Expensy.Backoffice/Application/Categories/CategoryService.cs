using Microsoft.EntityFrameworkCore;
using REM.Expensy.Backoffice.Entities;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Application.Categories;

/// <summary>
/// Handles CRUD operations for categories.
/// System categories are read-only; user-owned categories are fully manageable by their owner.
/// </summary>
public class CategoryService : ICategoryService
{
    private readonly IContext _context;

    public CategoryService(IContext context)
    {
        _context = context;
    }

    /// <inheritdoc/>
    public async Task<IReadOnlyList<CategoryDto>> GetAllAsync(string userId, CancellationToken ct = default)
    {
        var categories = await _context.Categories
            .AsNoTracking()
            .OrderByDescending(c => c.IsSystem)
            .ThenBy(c => c.Name)
            .Select(c => new CategoryDto(c.Id, c.Name, c.Icon, c.Color, c.IsSystem))
            .ToListAsync(ct)
            .ConfigureAwait(false);

        return categories;
    }

    /// <inheritdoc/>
    public async Task<CategoryDto?> GetByIdAsync(Guid id, string userId, CancellationToken ct = default)
    {
        var category = await _context.Categories
            .AsNoTracking()
            .Where(c => c.Id == id)
            .Select(c => new CategoryDto(c.Id, c.Name, c.Icon, c.Color, c.IsSystem))
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        return category;
    }

    /// <inheritdoc/>
    public async Task<CategoryDto> CreateAsync(CreateCategoryRequest request, string userId, CancellationToken ct = default)
    {
        var category = new Category
        {
            Name = request.Name,
            Icon = request.Icon,
            Color = request.Color,
            IsSystem = false
        };

        await _context.Categories.AddAsync(category, ct).ConfigureAwait(false);
        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return new CategoryDto(category.Id, category.Name, category.Icon, category.Color, category.IsSystem);
    }

    /// <inheritdoc/>
    public async Task<CategoryDto?> UpdateAsync(Guid id, UpdateCategoryRequest request, string userId, CancellationToken ct = default)
    {
        var category = await _context.Categories
            .Where(c => c.Id == id)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (category is null)
            return null;

        if (category.IsSystem)
            throw new InvalidOperationException("System categories cannot be modified.");

        category.Name = request.Name;
        category.Icon = request.Icon;
        category.Color = request.Color;

        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return new CategoryDto(category.Id, category.Name, category.Icon, category.Color, category.IsSystem);
    }

    /// <inheritdoc/>
    public async Task<bool> DeleteAsync(Guid id, string userId, CancellationToken ct = default)
    {
        var category = await _context.Categories
            .Where(c => c.Id == id)
            .FirstOrDefaultAsync(ct)
            .ConfigureAwait(false);

        if (category is null)
            return false;

        if (category.IsSystem)
            throw new InvalidOperationException("System categories cannot be deleted.");

        category.IsDeleted = true;

        await _context.SaveChangesAsync(ct).ConfigureAwait(false);

        return true;
    }
}
