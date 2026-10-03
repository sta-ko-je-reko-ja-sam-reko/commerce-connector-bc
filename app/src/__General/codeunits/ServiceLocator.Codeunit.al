namespace CommerceConnector.General;

using CommerceConnector.Events;
using CommerceConnector.Orders;

codeunit 70030 "CMC Service Locator"
{
    SingleInstance = true;
    Access = Public;

    var
        IReactions: Interface "CMC IReactions";
        IReactionsDefined: Boolean;
        IOrderIntake: Interface "CMC IOrderIntake";
        IOrderIntakeDefined: Boolean;

    /// <summary>
    /// Returns the implementation that reacts to base application events.
    /// </summary>
    procedure Reactions(): Interface "CMC IReactions"
    begin
        if not IReactionsDefined then
            ImplementReactions(ResolveDefaultReactions());
        exit(IReactions);
    end;

    /// <summary>
    /// Substitutes the reaction implementation. Takes precedence over the resolution event.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure ImplementReactions(Implementation: Interface "CMC IReactions")
    begin
        IReactions := Implementation;
        IReactionsDefined := true;
    end;

    /// <summary>
    /// Returns the implementation that turns staged orders into sales documents.
    /// </summary>
    procedure OrderIntake(): Interface "CMC IOrderIntake"
    begin
        if not IOrderIntakeDefined then
            ImplementOrderIntake(ResolveDefaultOrderIntake());
        exit(IOrderIntake);
    end;

    /// <summary>
    /// Substitutes the order intake implementation. Takes precedence over the resolution event.
    /// </summary>
    /// <param name="Implementation">The implementation to use for the remainder of the session.</param>
    procedure ImplementOrderIntake(Implementation: Interface "CMC IOrderIntake")
    begin
        IOrderIntake := Implementation;
        IOrderIntakeDefined := true;
    end;

    /// <summary>
    /// Returns the change type recorded when a record is created.
    /// </summary>
    procedure CreatedChangeType(): Text
    var
        CommerceReactions: Codeunit "CMC Commerce Reactions";
    begin
        exit(CommerceReactions.CreatedChangeType());
    end;

    /// <summary>
    /// Returns the change type recorded when a record is updated.
    /// </summary>
    procedure UpdatedChangeType(): Text
    var
        CommerceReactions: Codeunit "CMC Commerce Reactions";
    begin
        exit(CommerceReactions.UpdatedChangeType());
    end;

    /// <summary>
    /// Returns the change type recorded when a record is removed.
    /// </summary>
    procedure DeletedChangeType(): Text
    var
        CommerceReactions: Codeunit "CMC Commerce Reactions";
    begin
        exit(CommerceReactions.DeletedChangeType());
    end;

    local procedure ResolveDefaultReactions(): Interface "CMC IReactions"
    var
        DefaultImplementation: Codeunit "CMC Commerce Reactions";
        Implementation: Interface "CMC IReactions";
    begin
        Implementation := DefaultImplementation;
        OnResolveReactions(Implementation);
        exit(Implementation);
    end;

    local procedure ResolveDefaultOrderIntake(): Interface "CMC IOrderIntake"
    var
        DefaultImplementation: Codeunit "CMC Order Intake";
        Implementation: Interface "CMC IOrderIntake";
    begin
        Implementation := DefaultImplementation;
        OnResolveOrderIntake(Implementation);
        exit(Implementation);
    end;

    /// <summary>
    /// Raised once per session when the reaction implementation is first resolved.
    /// </summary>
    /// <param name="Implementation">Seeded with the default. Assign to substitute another implementation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnResolveReactions(var Implementation: Interface "CMC IReactions")
    begin
    end;

    /// <summary>
    /// Raised once per session when the order intake implementation is first resolved.
    /// </summary>
    /// <param name="Implementation">Seeded with the default. Assign to substitute another implementation.</param>
    [IntegrationEvent(false, false)]
    local procedure OnResolveOrderIntake(var Implementation: Interface "CMC IOrderIntake")
    begin
    end;
}
