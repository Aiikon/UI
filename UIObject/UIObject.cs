using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.ComponentModel;
using System.Linq;
using System.Management.Automation;

namespace Rhodium.UI
{
    public class UIObject : CustomTypeDescriptor, INotifyPropertyChanged
    {
        internal readonly List<PropertyDescriptor> propertyDescriptorList = new List<PropertyDescriptor>();
        internal readonly Dictionary<string, PropertyDescriptor> propertyDescriptorDict = new Dictionary<string, PropertyDescriptor>(StringComparer.OrdinalIgnoreCase);
        internal readonly ConcurrentDictionary<string, object> valueDict = new ConcurrentDictionary<string, object>(StringComparer.OrdinalIgnoreCase);

        public event PropertyChangedEventHandler PropertyChanged;

        private static Type GetValueType(object value)
        {
            if (value == null)
                return typeof(object);

            if (!(value is PSObject))
                return value.GetType();

            PSObject valueAsPsObject = (PSObject)value;
            if (valueAsPsObject.BaseObject == null || valueAsPsObject.BaseObject is PSObject)
                return typeof(PSObject);

            return valueAsPsObject.BaseObject.GetType();
        }

        internal void SetProperty(string name, object value)
        {
            if (!propertyDescriptorDict.ContainsKey(name))
            {
                var propertyDescriptor = new UIObjectPropertyDescriptor(name, GetValueType(value));
                propertyDescriptorList.Add(propertyDescriptor);
                propertyDescriptorDict[name] = propertyDescriptor;
            }

            // Because the UI will hate you unless you do this:
            if (value is PSObject && ((PSObject)value).BaseObject != null)
                value = ((PSObject)value).BaseObject;

            bool changed = false;
            if (valueDict.ContainsKey(name) && valueDict[name] != null && value != null)
                changed = !value.Equals(valueDict[name]);

            valueDict[name] = value;

            if (changed)
                NotifyPropertyChanged(name);
        }

        public static UIObject FromPSObject(PSObject BaseObject)
        {
            UIObject uiObject = new UIObject();
            if (BaseObject == null)
                return uiObject;

            foreach (var property in BaseObject.Properties)
                uiObject.SetProperty(property.Name, property.Value);

            return uiObject;
        }

        public static UIObject FromDictionary(IDictionary<string,object> Dictionary)
        {
            UIObject uiObject = new UIObject();
            if (Dictionary == null)
                return uiObject;

            foreach (string propertyName in Dictionary.Keys)
                uiObject.SetProperty(propertyName, Dictionary[propertyName]);

            return uiObject;
        }

        internal void NotifyPropertyChanged(string propertyName)
        {
            if (PropertyChanged != null)
                PropertyChanged(this, new PropertyChangedEventArgs(propertyName));
        }

        public override PropertyDescriptorCollection GetProperties()
        {
            return new PropertyDescriptorCollection(propertyDescriptorList.ToArray());
        }

        public override PropertyDescriptorCollection GetProperties(Attribute[] attributes)
        {
            return GetProperties();
        }

        public override EventDescriptorCollection GetEvents()
        {
            return null;
        }

        public override EventDescriptorCollection GetEvents(Attribute[] attributes)
        {
            return null;
        }

        private class UIObjectPropertyDescriptor : PropertyDescriptor
        {
            internal readonly Type _type;

            public UIObjectPropertyDescriptor(string name, Type type) : base(name, null)
            {
                _type = type;
            }

            public override bool CanResetValue(object component)
            {
                throw new NotImplementedException();
            }

            public override Type ComponentType
            {
                get { throw new NotImplementedException(); }
            }

            public override bool IsReadOnly
            {
                get { return false; }
            }

            public override Type PropertyType
            {
                get { return _type; }
            }

            public override object GetValue(object component)
            {
                UIObject uiObject = (UIObject)component;
                object value = null;
                uiObject.valueDict.TryGetValue(Name, out value);
                return value;
            }

            public override void ResetValue(object component)
            {
                throw new NotImplementedException();
            }

            public override void SetValue(object component, object value)
            {
                UIObject uiObject = (UIObject)component;
                uiObject.SetProperty(Name, value);
            }

            public override bool ShouldSerializeValue(object component)
            {
                throw new NotImplementedException();
            }
        }
    }

    public sealed class UIObjectAdapter : PSPropertyAdapter
    {
        public override Collection<PSAdaptedProperty> GetProperties(object baseObject)
        {
            var uiObject = baseObject as UIObject;
            if (uiObject == null) return null;

            var result = new Collection<PSAdaptedProperty>();
            foreach (var property in uiObject.propertyDescriptorList)
                result.Add(new PSAdaptedProperty(property.Name, uiObject.valueDict[property.Name]));

            return result;
        }

        public override PSAdaptedProperty GetProperty(object baseObject, string propertyName)
        {
            var uiObject = baseObject as UIObject;
            if (uiObject == null) return null;

            if (!uiObject.valueDict.ContainsKey(propertyName))
                return new PSAdaptedProperty(propertyName, null);
            return new PSAdaptedProperty(propertyName, uiObject.valueDict[propertyName]);
        }

        public override string GetPropertyTypeName(PSAdaptedProperty adaptedProperty)
        {
            var uiObject = adaptedProperty.BaseObject as UIObject;
            if (uiObject == null) return null;

            var propertyDescriptor = uiObject.propertyDescriptorDict[adaptedProperty.Name];
            if (propertyDescriptor == null)
                return null;

            return propertyDescriptor.PropertyType.FullName;
        }

        public override object GetPropertyValue(PSAdaptedProperty adaptedProperty)
        {
            var uiObject = adaptedProperty.BaseObject as UIObject;
            if (uiObject == null) return null;

            return uiObject.valueDict[adaptedProperty.Name];
        }

        public override bool IsGettable(PSAdaptedProperty adaptedProperty)
        {
            return true;
        }

        public override bool IsSettable(PSAdaptedProperty adaptedProperty)
        {
            return true;
        }

        public override void SetPropertyValue(PSAdaptedProperty adaptedProperty, object value)
        {
            var uiObject = adaptedProperty.BaseObject as UIObject;
            if (uiObject == null) return;

            uiObject.SetProperty(adaptedProperty.Name, value);
        }

        public override Collection<string> GetTypeNameHierarchy(object baseObject)
        {
            var result = new Collection<string>();
            result.Add("System.Object");
            return result;
        }
    }

    public class UIObjectCollection : ObservableCollection<UIObject>, INotifyPropertyChanged
    {
        public new event PropertyChangedEventHandler PropertyChanged;

        public void RaiseCountChanged()
        {
            if (PropertyChanged != null)
                PropertyChanged(this, new PropertyChangedEventArgs("Count"));
        }

        public new void Add(UIObject item)
        {
            base.Add(item);
            RaiseCountChanged();
        }

        public void AddWithDispatcher(UIObject uiObject, System.Windows.Threading.Dispatcher dispatcher)
        {
            dispatcher.BeginInvoke(new Action(() => {
                base.Add(uiObject);
            }));
            RaiseCountChanged();
        }

        public new void Insert(int index, UIObject item)
        {
            base.Insert(index, item);
            RaiseCountChanged();
        }

        public new void Remove(UIObject item)
        {
            base.Remove(item);
            RaiseCountChanged();
        }

        public new void Clear()
        {
            base.Clear();
            RaiseCountChanged();
        }
    }
}