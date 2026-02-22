using System.Diagnostics;
using System.Reflection;

namespace REM.Expensy.Backoffice.Helpers;

public static class ReflectionHelper
{
    public static object? InvokeGenericMethod(Type type, object? instance, string methodName, Type[] genericTypes, params object[] arguments)
    {
        MethodInfo? method = type
            .GetMethods(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static)
            .SingleOrDefault(t => t.IsGenericMethod && t.Name == methodName);

        Debug.Assert(method != null);

        return method.MakeGenericMethod(genericTypes).Invoke(instance, arguments);
    }

    public static Task<object?> InvokeGenericMethodAsync(Type type, object? instance, string methodName, Type[] genericTypes, params object[] arguments)
    {
        MethodInfo? method = type
        .GetMethods(BindingFlags.Public | BindingFlags.NonPublic | BindingFlags.Instance | BindingFlags.Static)
        .SingleOrDefault(t => t.IsGenericMethod && t.Name == methodName);

        Debug.Assert(method != null);

        return method.MakeGenericMethod(genericTypes).InvokeAsync(instance, arguments);
    }
}

public static class MethodInfoExtensions
{
    public static async Task<object?> InvokeAsync(this MethodInfo method, object? obj, params object[] parameters)
    {
        var result = method.Invoke(obj, parameters);
        if (result != null)
        {
            var task = (Task)result;
            await task.ConfigureAwait(false);
            var resultProperty = task.GetType().GetProperty("Result");
            return resultProperty?.GetValue(task);
        }
        return null;
    }
}
