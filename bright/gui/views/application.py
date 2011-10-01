from traits.api import HasTraits, Any, Instance, on_trait_change, DelegatesTo, Dict, List, Set, Str, File, Button, Enum, Bool, Event
from traitsui.api import View, InstanceEditor, Item, HGroup, VGroup, Tabbed, CodeEditor, ShellEditor, FileEditor, TitleEditor, TableEditor, ListEditor, ListStrEditor, Handler, ToolBar, Action, MenuBar, Menu
from traitsui.file_dialog import open_file, save_file
from enable.api import ComponentEditor
from bright.gui.models.fuel_cycle_model import FuelCycleModel
from graphcanvas.api import GraphView
import os
import re
from CustomNodeSelectionTool import CustomNodeSelectionTool
from traits.trait_handlers import BaseTraitHandler, TraitHandler
import random

class E_handler(Handler):
    file_name = File

    def save_file(self, info):
        
        if info.object.save == True:
            info.object.save = False
        else:
            info.object.save = True
        return
    def open_file(self, info):
        if info.object.open == True:
            info.object.open = False
        else:
            info.object.open = True
        return
    
    save = Action(name = "Save", action = "save_file")
    open = Action(name = "Open", action = "open_file")


class Application(HasTraits):
    model = Instance(FuelCycleModel)
    graph_view = Instance(GraphView)
    _container = DelegatesTo('graph_view')
    script = DelegatesTo('model')
    model_context = Dict
    #graph_changed_event = DelegatesTo('model')
    #classes_available = Dict
    classes_list = List(Str)
    variables_list = List
    file_name = File
    file_name2 = File
    open = Bool
    save = Bool
    class_title = Enum('Classes Available')
    component_views = Dict
    loaded_script = Str
    handle = E_handler()
    something = Event    
    activated_formation = Any
    instancekey = Dict



    def register_views(self):
        localdict = {}
        file_dir = os.path.split(__file__)[0]
        comp_dir = os.path.join(file_dir, 'component_views/')
        comp_list = os.listdir(comp_dir)
        comp_list.remove('views')
        comp_list.remove('__init__.py')
        for i in comp_list:
            if 'init' not in i and 'util' not in i and 'lwr' not in i:
                match = re.search('(.+).py',i)
                vname_list = match.group(1).split("_")
                for n in vname_list:
                    vname_list[vname_list.index(n)] = n.capitalize()
                vname = ''.join(vname_list)
                exec('from bright.gui.views.component_views.{name} import {view_name}View'.format(name=match.group(1), view_name=vname), {}, localdict)
        for key, value in localdict.items():
            self.component_views[key] = value
        
    traits_view = View(
                     VGroup(
                        HGroup(
                            #Item('open', show_label = False, width = .05),
                            #Item('save', show_label = False, width = .05),
                            #Item('file_name', show_label = False, width = .05)
                            
                              ),
                        HGroup(
                            Item('classes_list', editor = ListStrEditor(activated = 'activated_formation', title = 'Classes Available', editable = False, operations = []), show_label = False, width =.25),
                            #Item('classes_list', editor = ListEditor(trait_handler=instance_handler), style = 'readonly', show_label = False, resizable = True, width =.25),
                            Item('_container', editor = ComponentEditor(), show_label = False, resizable = True, width =.25),
                            Item('script', editor = CodeEditor(), show_label = False, resizable = True, width = .50)
                            ),
                        HGroup(
                            Item('variables_list', editor = ListStrEditor(title = 'Variables In Use', editable = False), show_label = False, resizable = True, width =.17),
                            #Item('variables_list', editor = ListEditor(), style = 'readonly', show_label = False, resizable = True, width =.17),
                            Item('model_context', editor = ShellEditor(share = True), show_label = False)
                              )
                          ),
                  resizable = True,
                  handler = handle,
                  title = "Fuel Cycle Model",
                  menubar = MenuBar(Menu(handle.open, handle.save, name = "File"))
                    )
    
    def _activated_formation_changed(self):
        self.model.add_instance(self.instancekey[self.activated_formation] + str(random.randint(0,9)), self.activated_formation) 
        


    def _model_default(self):
        fcm = FuelCycleModel()
        fcm.add_instance("nu", "MassStream", {922380:0.992745, 922350:0.0072, 922340:0.000055})
        fcm.add_instance("sr1", "Storage")
        fcm.calc_comp("sr1","nu")
        self.register_views()
        return fcm

    #@on_trait_event('model.graph_changed_event')
    def update_graph_view(self):
        #print "yo dudes i'm workin"
        self.graph_view.graph = self.model.graph
        self.graph_view._graph_changed(self.model.graph)
        #self.graph_view = GraphView(graph =self.model.graph)
        #gv = GraphView(graph = self.model.graph)

        #gv._canvas.tools.append(CustomNodeSelectionTool(classes_available = self.model.classes_available, variables_available = self.model.variables, class_views = self.component_views, component=gv._canvas))
           
    def _graph_view_default(self):
        self.on_trait_event(self.update_graph_view, 'model.graph_changed_event')
        gv = GraphView(graph = self.model.graph)
        #import pdb; pdb.set_trace()
        gv._canvas.tools.pop(0)
        gv._canvas.tools.append(CustomNodeSelectionTool(classes_available = self.model.classes_available, variables_available = self.model.variables, class_views = self.component_views, component=gv._canvas))
        return gv
    
    def _model_context_default(self):
        return {'fc': self.model}

    def _classes_list_default(self):
        fcm = FuelCycleModel()
        list_temp = []
        for key, value in fcm.classes_available.items():
            list_temp.append(key)
        return list_temp

    def _variables_list_default(self):
        temp_list = []    
        for key, value in self.model.variables.items():
            temp_list.append(key)
        return temp_list

    def _script_changed(self):
        temp_list = []
        for key, value in self.model.variables.items():
            temp_list.append(key)
        self.variables_list  = temp_list

    def _open_changed(self):
        file_name = open_file()
        if file_name != '':
            self.loaded_script = file_name 
            #self.file_name = file_name
        #self.open = False

    def _save_changed(self):
        file_name = save_file()
        if file_name != '':
            with open(file_name, 'w') as f:
                f.write(self.script)
        #self.save = False
        #if file_name != '':
         #   self.file_name2 = save_file
    
    def _instancekey_default(self):
        tempdict = {}
        for i in self.classes_list:
            tempdict[i] = i[0] + i[1] + i[2]
        return tempdict

if __name__ == '__main__':
    app = Application()
    #app.register_views()
    app.configure_traits()
    

