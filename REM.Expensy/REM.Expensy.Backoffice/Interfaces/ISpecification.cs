using System.Linq.Expressions;

namespace REM.Expensy.Backoffice.Interfaces
{
    public interface ISpecification<T> where T : class
    {
        List<Expression<Func<T, bool>>> Criterias { get; }
        List<Expression<Func<T, object>>> Includes { get; }
        List<string> IncludeStrings { get; }
        Expression<Func<T, object>> OrderBy { get; }
        Expression<Func<T, object>> OrderByDescending { get; }
        Expression<Func<T, object>> ThenBy { get; }
        Expression<Func<T, object>> ThenByDescending { get; }
        Expression<Func<T, object>> GroupBy { get; }
    }
}