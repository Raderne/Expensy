namespace REM.Expensy.Backoffice.Entities.Common;

public abstract class IdBasedEntity<TId>
{
    public virtual TId Id { get; set; }
    public override bool Equals(object? obj)
    {
        if (obj == null) return false;
        if (obj == this) return true;
        if (obj.GetType() != GetType()) return false;
        var other = (IdBasedEntity<TId>)obj;
        if (Id == null)
        {
            if (other.Id != null) return false;
        }
        else if (!Id.Equals(other.Id)) return false;

        return true;
    }
    public override int GetHashCode()
    {
        var prime = 31;
        var result = 1;

        return prime * result + (Id == null ? 0 : Id.GetHashCode());
    }
}
