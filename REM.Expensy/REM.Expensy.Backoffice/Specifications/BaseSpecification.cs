using REM.Expensy.Backoffice.Enums;
using REM.Expensy.Backoffice.Interfaces;
using System.Linq.Expressions;

namespace REM.Expensy.Backoffice.Specifications;

public abstract class BaseSpecification<T> : ISpecification<T> where T : class
{
    protected BaseSpecification(Expression<Func<T, bool>> criteria)
    {
        AddCriteria(criteria);
    }

    protected BaseSpecification()
    {
    }

    public List<Expression<Func<T, bool>>> Criterias { get; } = new List<Expression<Func<T, bool>>>();
    public List<Expression<Func<T, object>>> Includes { get; } = new List<Expression<Func<T, object>>>();
    public List<string> IncludeStrings { get; } = new List<string>();
    public Expression<Func<T, object>> OrderBy { get; private set; }
    public Expression<Func<T, object>> OrderByDescending { get; private set; }
    public Expression<Func<T, object>> ThenBy { get; private set; }
    public Expression<Func<T, object>> ThenByDescending { get; private set; }
    public Expression<Func<T, object>> GroupBy { get; private set; }

    protected virtual void AddCriteria(Expression<Func<T, bool>> criteria)
    {
        Criterias.Add(criteria);
    }

    protected virtual void AddInclude(Expression<Func<T, object>> includeExpression)
    {
        Includes.Add(includeExpression);
    }


    protected virtual void AddInclude(string includestring)
    {
        IncludeStrings.Add(includestring);
    }

    protected virtual void ApplyOrderBy(string propertyName, SortDirection sortDirection)
    {
        var arg = Expression.Parameter(typeof(T), "x");
        var property = Expression.Property(arg, propertyName);
        var converted = Expression.Convert(property, typeof(object));
        var selector = Expression.Lambda<Func<T, object>>(converted, new ParameterExpression[] { arg });

        if (sortDirection == SortDirection.DESC)
            OrderByDescending = selector;
        else
            OrderBy = selector;
    }

    protected virtual void ApplyThenBy(string propertyName, SortDirection sortDirection)
    {
        var arg = Expression.Parameter(typeof(T), "x");
        var property = Expression.Property(arg, propertyName);
        var converted = Expression.Convert(property, typeof(object));
        var selector = Expression.Lambda<Func<T, object>>(converted, new ParameterExpression[] { arg });

        if (sortDirection == SortDirection.DESC)
            ThenByDescending = selector;
        else
            ThenBy = selector;

    }

    protected virtual void ApplyOrderBy(Expression<Func<T, object>> orderByExpression)
    {
        OrderBy = orderByExpression;
    }

    protected virtual void ApplyOrderByDescending(Expression<Func<T, object>> orderByDescendingExpression)
    {
        OrderByDescending = orderByDescendingExpression;
    }

    protected virtual void ApplyGroupBy(Expression<Func<T, object>> groupByExpression)
    {
        GroupBy = groupByExpression;
    }
}