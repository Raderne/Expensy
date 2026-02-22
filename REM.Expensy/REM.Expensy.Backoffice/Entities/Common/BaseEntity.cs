using REM.Expensy.Backoffice.Interfaces;

namespace REM.Expensy.Backoffice.Entities.Common;

public abstract class BaseEntity : BaseEntity<Guid>
{
}

public abstract class BaseEntity<TId> : IdBasedEntity<TId>, IDeletableEntity, IAuditableEntity<string>
{
    public virtual string CreatedBy { get; set; }
    public virtual DateTime Created { get; set; }
    public virtual string LastModifiedBy { get; set; }
    public virtual DateTime? LastModified { get; set; }
    public bool? IsDeleted { get; set; }
}
