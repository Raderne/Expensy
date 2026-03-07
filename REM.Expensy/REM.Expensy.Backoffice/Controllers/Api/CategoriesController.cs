using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using REM.Expensy.Backoffice.Application.Categories;
using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Controllers.Api;

/// <summary>
/// Endpoints for categories. System categories are read-only; user-owned categories support full CRUD.
/// </summary>
[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
[Authorize]
public class CategoriesController : ControllerBase
{
    private readonly ICategoryService _categoryService;
    private readonly ICurrentUserService _currentUserService;
    private readonly ILogger<CategoriesController> _logger;

    public CategoriesController(
        ICategoryService categoryService,
        ICurrentUserService currentUserService,
        ILogger<CategoriesController> logger)
    {
        _categoryService = categoryService;
        _currentUserService = currentUserService;
        _logger = logger;
    }

    /// <summary>
    /// Returns all system categories and categories owned by the current user.
    /// </summary>
    [HttpGet]
    [ProducesResponseType(typeof(IReadOnlyList<CategoryDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<IReadOnlyList<CategoryDto>>> GetAll(CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting all categories for user {UserId}", _currentUserService.UserId);

        var categories = await _categoryService
            .GetAllAsync(_currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        return Ok(categories);
    }

    /// <summary>
    /// Returns a single category by ID (system or user-owned).
    /// </summary>
    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(CategoryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CategoryDto>> GetById(Guid id, CancellationToken cancellationToken)
    {
        _logger.LogDebug("Getting category {CategoryId} for user {UserId}", id, _currentUserService.UserId);

        var category = await _categoryService
            .GetByIdAsync(id, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        if (category is null)
            return NotFound();

        return Ok(category);
    }

    /// <summary>
    /// Creates a new user-owned category.
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(CategoryDto), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<ActionResult<CategoryDto>> Create([FromBody] CreateCategoryRequest request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        _logger.LogDebug("Creating category for user {UserId}", _currentUserService.UserId);

        var category = await _categoryService
            .CreateAsync(request, _currentUserService.UserId, cancellationToken)
            .ConfigureAwait(false);

        return CreatedAtAction(nameof(GetById), new { id = category.Id }, category);
    }

    /// <summary>
    /// Updates a user-owned category. Returns 403 if the category is a system category.
    /// </summary>
    [HttpPut("{id:guid}")]
    [ProducesResponseType(typeof(CategoryDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<ActionResult<CategoryDto>> Update(Guid id, [FromBody] UpdateCategoryRequest request, CancellationToken cancellationToken)
    {
        if (!ModelState.IsValid)
            return ValidationProblem(ModelState);

        _logger.LogDebug("Updating category {CategoryId} for user {UserId}", id, _currentUserService.UserId);

        try
        {
            var category = await _categoryService
                .UpdateAsync(id, request, _currentUserService.UserId, cancellationToken)
                .ConfigureAwait(false);

            if (category is null)
                return NotFound();

            return Ok(category);
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Business rule violation updating category {CategoryId} for user {UserId}", id, _currentUserService.UserId);
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status403Forbidden);
        }
    }

    /// <summary>
    /// Soft-deletes a user-owned category. Returns 403 if the category is a system category.
    /// </summary>
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(Guid id, CancellationToken cancellationToken)
    {
        _logger.LogDebug("Deleting category {CategoryId} for user {UserId}", id, _currentUserService.UserId);

        try
        {
            var deleted = await _categoryService
                .DeleteAsync(id, _currentUserService.UserId, cancellationToken)
                .ConfigureAwait(false);

            if (!deleted)
                return NotFound();

            return NoContent();
        }
        catch (InvalidOperationException ex)
        {
            _logger.LogWarning(ex, "Business rule violation deleting category {CategoryId} for user {UserId}", id, _currentUserService.UserId);
            return Problem(detail: ex.Message, statusCode: StatusCodes.Status403Forbidden);
        }
    }
}
